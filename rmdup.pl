#!/usr/bin/perl -w

use strict;
use warnings;
use Data::Dumper;
use Digest::SHA;
use Cwd qw(realpath);
use File::Find qw(find);

my $subjectDir = shift or die "Usage: $0 dir_to_check [delete_regex_pattern]";
my $deletePattern = shift;

unless ( -e $subjectDir ) {
    print "Directory $subjectDir not found.";
    exit;
}

$|++; # turn off output buffering;
my @chars = qw(| / - \ );
my $i = 0;

my %duplicateCandidates;

print "Starting file check...\n ";

find ({ wanted => \&processFile, follow => 1}, $subjectDir);

print "\n";


foreach my $key (keys(%duplicateCandidates)) {
    my $deletionCandidate = $duplicateCandidates{$key};
    if (scalar @{ $duplicateCandidates{$key} } < 2) {
        delete $duplicateCandidates{$key};
    } else {
        my $filesLeft = scalar @{ $duplicateCandidates{$key} };
        foreach my $file (@$deletionCandidate) {
            print "Files left: $filesLeft - checking \"$file\" for deletion\n";
            if ($filesLeft > 1) {
                if ($deletePattern && ($file =~ m/$deletePattern/)) {
                    print "  ===> #### Pattern matches, enough files left, so would like to delete \"$file\" ####\n";
                    unlink $file;
                    $filesLeft--;
                } else {
                    print "  ===> Pattern doesn't match or is not defined.\n"
                }
            } else {
                print "  ===> Not enough files left, need at least 1 to not lose data :-S\n"
            }
        }
        print"\n";
    }
}
#print "Found the following duplicates:\n";
#print Dumper(\%duplicateCandidates);


sub processFile {
    
    my $file = $_;
    
    print "\c[[K", $chars[++$i % @chars], " Processing \"", $file, "\"\r";

    if ( -d $file || -l $file ) {
        return;
    }
    my $realFilePath = Cwd::realpath($file);
    if ($realFilePath =~ m/(\/\@eaDir\/)/) {
        return;
    }

    my $fh;
    unless (open $fh, $file) {
        warn "$0: open $file: $!";
        return;
    }
    
    my $sha = Digest::SHA->new(256);
    $sha->addfile($fh);
    my $checksum = $sha->hexdigest;
    
    push @{ $duplicateCandidates{$checksum} }, $realFilePath;
    
    close $fh;
}
