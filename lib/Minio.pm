package Minio;

use strict;
use JSON::XS;

our $VERSION = '0.01';

sub new {
  my $class = shift;
  my $X = {};
  my %Args = @_;

  my $MinioEXE = $Args{'minio_path'} || FindFile('minio-mc', [split /:/,$ENV{'PATH'}]);

  die "\ncan't find Minio client".($Args{'minio_path'}?" [".$Args{'minio_path'}."]":"")
    ."\n\ninstall Minio-client and use 'minio_path_dir' parameter\nhttps://docs.min.io/docs/minio-client-quickstart-guide.html\n\n"
      if !$MinioEXE || !-f $MinioEXE;

  unless (CheckMinioConfig($Args{'minio_config_dir'})) {
    die "Can't find Minio-config path or config corrupted. Use 'minio_config' parameter.";
  }

  $X->{'json'} = $Args{'json'} || 1;
  $X->{'debug'} = $Args{'debug'} || 0;
  $X->{'minio_exe'} = $MinioEXE;
  $X->{'minio_config'} = $Args{'minio_config_dir'};

  bless $X, $class;
  return $X;
}

sub _ex {
  my $X = shift;
  my $Str = shift;
  my $Args = shift;

  die 'invalid options format. cmd(bucket,{option=>1,option=>2})' if defined $Args && ref $Args ne 'HASH';

  my $ToJson = $X->{'json'} && !(exists $Args->{'json'} && $Args->{'json'}==0);
  my $Force = $Args->{'force'};

  my $Cmd = $X->{'minio_exe'}.' -C '.$X->{'minio_config'}.' '.($ToJson?'--json ':'').$Str;
  print "Command: ".$Cmd."\n" if $X->{'debug'};
  my $Ex = `$Cmd 2>&1`;
  #print "EX ".$Ex."\n";

  if ($ToJson) {
    my $JSON;
    eval {
      $Ex =~ s/}[\n\r]{/},{/g;
      $Ex = '['.$Ex.']';
      $JSON = decode_json($Ex);
      if (!$Args->{'as_array'} && scalar @$JSON == 1) {
        $JSON = $JSON->[0];
        $Ex =~ s/^\[//;
        $Ex =~ s/\]$//;
      } 
    };
    if ($@) {
      return "[ERROR] ".$Ex;      
    }
    my $R = {
      json=>$Ex,
      data=>$JSON,
    };
    $R->{'error'} = $JSON->{error}->{cause}->{message} || $JSON->{error}->{message}
      if ref $JSON eq 'HASH' && $JSON->{status} eq 'error';
    return $R;
  }
  return $Ex;
}

sub LS {
  my $X = shift;
  my $BucketName = shift || return {error=>"Bucket name not defined"};
  my $Args = shift;
  my $Cmd = 'ls '.$BucketName;
  $Args->{'as_array'}=1;
  return $X->_ex($Cmd, $Args);
}

sub Tree {
  my $X = shift;
  my $BucketName = shift || return {error=>"Bucket name not defined"};
  my $Args = shift;
  my $Cmd = 'tree '.$BucketName;
  $Args->{'as_array'}=1;
  return $X->_ex($Cmd, $Args);
}

sub Local2Minio {
  my $X = shift;
  my $Source = shift || return {error=>"Source not defined"};
  my $BucketName = shift || return {error=>"Destination not defined"};
  return {error=>"Source file '".$Source." not exists"}
    if !-f $Source && !-d $Source;
  my $Args = shift;
  my $Cmd = 'cp '.$Source.' '.$BucketName;
  return $X->_ex($Cmd, $Args);
}

sub Minio2Local {
  my $X = shift;
  my $BucketName = shift || return {error=>"Destination not defined"};
  my $Source = shift || return {error=>"Source not defined"};
  my $Args = shift;
  my $Cmd = 'cp '.$BucketName.' '.$Source;
  return $X->_ex($Cmd, $Args);
}

sub MakeBucket {
  my $X = shift;
  my $BucketName = shift || return {error=>"Bucket name not defined"};
  my $Args = shift;
  my $Cmd = 'mb '.$BucketName;
  return $X->_ex($Cmd, $Args);
}

sub DeleteBucket {
  my $X = shift;
  my $BucketName = shift || return {error=>"Bucket name not defined"};
  my $Args = shift;
  my $Cmd = 'rb '.($Args->{force}?'--force ':'').$BucketName;
  return $X->_ex($Cmd, $Args);
}

sub CheckMinioConfig {
  my $Path = shift || return undef;
  return undef unless -d $Path;
  return undef unless -f $Path.'/config.json';
  return 1;
}

sub FindFile {
  my $FileName = shift;
  my $Dirs = shift;
  foreach (@$Dirs) {
    my $Path = $_.'/'.$FileName;
    return $Path if -f $Path;
  }
  return undef;
}

1;
