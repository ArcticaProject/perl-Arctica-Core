################################################################################
#          _____ _
#         |_   _| |_  ___
#           | | | ' \/ -_)
#           |_| |_||_\___|
#                   _   _             ____            _           _
#    / \   _ __ ___| |_(_) ___ __ _  |  _ \ _ __ ___ (_) ___  ___| |_
#   / _ \ | '__/ __| __| |/ __/ _` | | |_) | '__/ _ \| |/ _ \/ __| __|
#  / ___ \| | | (__| |_| | (_| (_| | |  __/| | | (_) | |  __/ (__| |_
# /_/   \_\_|  \___|\__|_|\___\__,_| |_|   |_|  \___// |\___|\___|\__|
#                                                  |__/
#          The Arctica Modular Remote Computing Framework
#
################################################################################
#
# Copyright (C) 2015-2016 The Arctica Project
# http://http://arctica-project.org/
#
# This code is dual licensed: strictly GPL-2 or AGPL-3+
#
# GPL-2
# -----
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the
# Free Software Foundation, Inc.,
#
# 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
#
# AGPL-3+
# -------
# This programm is free software; you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This programm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
#
# Copyright (C) 2015-2016 Guangzhou Nianguan Electronics Technology Co.Ltd.
#                         <opensource@gznianguan.com>
# Copyright (C) 2015-2016 Mike Gabriel <mike.gabriel@das-netzwerkteam.de>
#
################################################################################
package Arctica::Core::Basics;
use strict;
use Exporter qw(import);
use Data::Dumper;# Remove this before release! (unless we're still depending on it.)
# Be very selective about what (if any) gets exported by default:
our @EXPORT = qw(genARandom);
# And be mindfull of what we lett the caller request here too:
our @EXPORT_OK = qw( aex_initNameClassVersion arcticaAArt );

sub aex_initNameClassVersion {
	my $Input = $_[0];
	my %NVC;
	if ($Input->{'app_name'} =~ /^([a-z0-9\_\-]*)$/) {
		$NVC{'app_name'} = $1;
	} else {
		$NVC{'app_name'} = "noname";
	}
	# At some point maybe check if the app_class is known,
	# if it has some initiation routines we'd want to do...
	# ...and if there is... do them!
	if ($Input->{'app_class'} =~ /^(aclient)$/) {# HEY!!! DUDE FIX THIS SOON!!!!
		$NVC{'app_class'} = $1;
	} else {
		$NVC{'app_class'} = "noclass";# YEAH, SERIOUSLY! WE GOT NO...!?!
	}

	if ($Input->{'app_version'} =~ /^(\d{1,}\.\d{1,}\.\d{1,}\.\d{1,})$/) {
		$NVC{'app_version'} = $1;
	} else {
		$NVC{'app_version'} = "0.0.0.0";#LAZY DEV FORGOT VERSION DECL!?!
	}

	($NVC{'self_aID'},$NVC{'parent_aID'}) = setncycle_parent_aid($NVC{'app_name'} );

	return %NVC;
}

sub setncycle_parent_aid {
	my $in_app_name = $_[0];
	my $ret_parent_aid = 0;
	if ($ENV{'A_PARENT_AID'} =~ /^([a-zA-Z0-9\_\-]*)$/) {
		$ret_parent_aid = $1;
	}

	my $new_random_id = genARandom('id',32);
	my $ret_self_aid = "$in_app_name\_$new_random_id";

	$ENV{'A_SELF_AID'} = $ret_self_aid;
	$ENV{'A_PARENT_AID'} = $ENV{'A_SELF_AID'};# So that our children may know our aID!

	return ($ret_self_aid, $ret_parent_aid);
}

sub genARandom {
	my $in_type = lc($_[0]);
	my $in_length = $_[1];
	$in_length =~ s/\D//g;
	if ($in_type eq "id") {
		if ($in_length =~ /^(\d{1,})$/) {
			$in_length = $1;
			if ($in_length < 16) {
				$in_length = 16;
			} elsif ($in_length > 64) {
				$in_length = 64;
			}
		} else {
			$in_length = 32;
		}
		srand();
		my $time = time();
		my @p_chars = ('a'..'z','A'..'Z');
		my $r_lenght = ($in_length - length($time));
		my $r_string;
		for (my $i=0; $i<$r_lenght; $i++) {
			$r_string .= $p_chars[int(rand($#p_chars + 1))];
		}
		return "$time$r_string";

	} elsif ($in_type eq "key") {
		if ($in_length =~ /^(\d{1,})$/) {
			$in_length = $1;
			if ($in_length < 64) {
				$in_length = 64;
			} elsif ($in_length > 256) {
				$in_length = 256;
			}
		} else {
			$in_length = 128;
		}
		srand();
		my @p_chars = ('0'..'9','a'..'z','A'..'Z');
		my $r_lenght = $in_length;
		my $r_string;
		for (my $i=0; $i<$r_lenght; $i++) {
			$r_string .= $p_chars[int(rand($#p_chars + 1))];
		}
		return $r_string;

	} elsif ($in_type eq "dirtail") {
		if ($in_length =~ /^(\d{1,})$/) {
			$in_length = $1;
			if ($in_length < 8) {
				$in_length = 8;
			} elsif ($in_length > 32) {
				$in_length = 32;
			}
		} else {
			$in_length = 8;
		}
		srand();
		my @p_chars = ('0'..'9','a'..'z','A'..'Z');
		my $r_lenght = $in_length;
		my $r_string;
		for (my $i=0; $i<$r_lenght; $i++) {
			$r_string .= $p_chars[int(rand($#p_chars + 1))];
		}
		return $r_string;

	} else {
		die("INVALID RANDOM TYPE?");
	}
}


sub arcticaAArt {
	# VERY CLUMSY... I KNOW.... THIS WAS DONE IN ZZZZZzzzzZZZZZZ MODE
	my $finalAArt;
	my $termwidth = 80;#keep this FIXED at 80!?
	my $boxIt = 0;
	my $baseAArt;
	$baseAArt .= "         _____ _\n        |_   _| |_  ___\n";
	$baseAArt .= "          | | | ' \\/ -_)\n          |_| |_||_\\___|\n";
	$baseAArt .= "                  _   _             ";
	$baseAArt .= "____            _           _\n";
	$baseAArt .= "   / \\   _ __ ___| |_(_) ___ __ _  ";
	$baseAArt .= "|  _ \\ _ __ ___ (_) ___  ___| |_\n";
	$baseAArt .= "  / _ \\ | '__/ __| __| |/ __/ _` | ";
	$baseAArt .= "| |_) | '__/ _ \\| |/ _ \\/ __| __|\n";
	$baseAArt .= " / ___ \\| | | (__| |_| | (_| (_| | ";
	$baseAArt .= "|  __/| | | (_) | |  __/ (__| |_\n";
	$baseAArt .= "/_/   \\_\\_|  \\___|\\__|_|\\___\\_";
	$baseAArt .= "_,_| |_|   |_|  \\___// |\\___|\\___|\\__|\n";
	$baseAArt .= "                                   ";
	$baseAArt .= "              |__/\n";
	my $baWidest = 0;
	my @baseArt = split(/\n/,$baseAArt);
	foreach my $baLine (@baseArt) {
		my $bALLenght = length($baLine);
		if ($bALLenght > $baWidest) {$baWidest = $bALLenght;}
	}
	my $leftPadding = (($termwidth - $baWidest)/2);
	foreach my $baLine (@baseArt) {
		if ($boxIt eq 1) {#$termwidth
			$baLine =~ s/^(.*)/'#' . ' ' x ($leftPadding-1) . $1 .
			 ' ' x ($termwidth-(length($baLine)+($leftPadding+1)))
			 . '#'/ge;
		} else {
			$baLine =~ s/^(.*)/' ' x $leftPadding . $1/ge;
		}
		$finalAArt .= "$baLine\n";
	}
	if ($boxIt eq 1) {#$termwidth
		$finalAArt =~ s/^(.*)/'#' x $termwidth . "\n". $1/e;
		$finalAArt =~ s/(.*)$/$1 . "\n#" . ' ' x ($termwidth-2).
		 "#\n". '#' x $termwidth . "\n"/e;
	}
	return $finalAArt;
}

1;
