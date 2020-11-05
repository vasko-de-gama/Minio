#!/usr/bin/perl

use strict;
use Data::Dumper;
use Cwd qw(cwd);
use Minio;

my $MObj = new Minio(
  'json' => 1,
  'debug' => 1,
  'minio_path' => cwd().'/minio-mc',
  'minio_config_dir' => cwd().'/minio',
);

#my $MB = $MObj->MakeBucket('myminio/pub');
#print Data::Dumper::Dumper($MB);

#my $MB = $MObj->DeleteBucket('myminio/pub', {forcde=>1});
#print Data::Dumper::Dumper($MB);

#exit;

my $L2M = $MObj->Local2Minio('/tmp/1.txt','myminio/pub/00/11/22/33/44/1.txt');
print Data::Dumper::Dumper($L2M);

my $M2L = $MObj->Minio2Local('myminio/pub/00/11/22/33/44/1.txt','/tmp/2.txt');
print Data::Dumper::Dumper($M2L);

##my $LS = $MObj->LS('myminio/pub');
##print Data::Dumper::Dumper($LS);

my $LS = $MObj->LS('myminio/pub/00');
print Data::Dumper::Dumper($LS);


#my $Tree = $MObj->Tree('myminio/pub',{json=>0});
#print Data::Dumper::Dumper($Tree);

