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
package Arctica::Core::ManageDirs;
use strict;
use Exporter qw(import);
use Arctica::Core::Basics;
use Arctica::Core::BugOUT::Basics qw( BugOUT );
use File::stat;

use Data::Dumper;# Remove this before release! (unless we're still dependant)

# Be very selective about what (if any) gets exported by default:
our @EXPORT = qw( new check_for_rtail_dir permZealot );
# And be mindfull of what we lett the caller request here too:
our @EXPORT_OK = qw( );

my %_CONF;


sub new {
	BugOUT(9,"ManageDir->new ENTER\n");
	my $class_name = $_[0];# Be EXPLICIT!! DON'T SHIFT OR "@_";
	my $DefaultTMP = "/tmp";# Load from Config?

	my $self = {
		isArctica => 1, # Declare that this is a Arctica "something"
	};

	if ((-d $ENV{'HOME'}) and (user_owns_it($ENV{'HOME'}))) {
		my $check_arctica_home = "$ENV{'HOME'}/.arctica";
		if ($check_arctica_home =~ /^(.*\/\.arctica)$/) {
			$check_arctica_home = $1;
		}

		unless (-d $check_arctica_home) {
			mkdir($check_arctica_home) 
				or die("ManageDirs: Failed to create .arctica 'HOME' directory");
		}

		permZealot($check_arctica_home);
		if (check_secure_permissions($check_arctica_home)) {
			$self->{'home_adir'} = $check_arctica_home;
		} else {
			die("ManageDirs: Unable to initiate .arctica HOME dir");
		}
	} else {die("The user is a homeless bum...");}

	if (-d $DefaultTMP) {

		if (my $gotDir = check_for_rtail_dir($DefaultTMP)) {
			# GOT DIR... LETS WORK WITH THAT....
			if (-d "$DefaultTMP/$gotDir") {
				BugOUT(9,"Found existing ADir: '$gotDir'");
				$self->{'tmp_adir'} = "$DefaultTMP/$gotDir";
			} else {
				die("Retesting full path failed: \"$DefaultTMP/$gotDir\"");
			}
		} else {
			BugOUT(9,"No ADir, lets create a new one!");
			my $gotDir = create_new_adir($DefaultTMP);
			if (-d "$DefaultTMP/$gotDir") {
				BugOUT(9,"Verified creation of: '$gotDir'");
				$self->{'tmp_adir'} = "$DefaultTMP/$gotDir";
			} else {
				die("Retesting full path failed: \"$DefaultTMP/$gotDir\"");
			}
		}
	} else {die("No TMP? ( $DefaultTMP )");}

	BugOUT(9,"ManageDir->new END\n");
	return $self;
}

sub permZealot {
	# IF WE CAN'T SET SECURE PERMISSIONS... DIE!
	my $the_path = $_[0];
	$the_path =~ s/\n//g;

	if (-f $the_path) {
		chmod(0600,$the_path) 
			or die("permZealot: Can't set permissions on \"$the_path\"!");

		unless (check_secure_permissions($the_path)) {
			die("permZealot Can't verify permissions on \"$the_path\"!");
		}
		BugOUT(9,"permZealot-> set chmod 0600 for file $the_path");
	} elsif (-d $the_path) {
		chmod(0700,$the_path) 
			or die("permZealot: Can't set permissions on \"$the_path\"!");

		unless (check_secure_permissions($the_path)) {
			die("permZealot: Can't verify permissions on \"$the_path\"!");
		}
		BugOUT(9,"permZealot-> set chmod 0600 for dir $the_path");
	} elsif (-S $the_path) {
		chmod(0700,$the_path) 
			or die("permZealot: Can't set permissions on \"$the_path\"!");

		unless (check_secure_permissions($the_path)) {
			die("permZealot: Can't verify permissions on \"$the_path\"!");
		}
		BugOUT(9,"permZealot-> set chmod 0600 for socket $the_path");
	} else {
		die("permZealot: Failed to set permissions on \"$the_path\"!");
	}
}

sub create_new_adir {
	BugOUT(9,"Entering 'create_new_adir'");
	my $the_tmp_dir = $_[0];
	my $the_sanetized_username = make_sane_userdir_name();
	my $the_random_dirtail = genARandom('dirtail',16);
	my $potential_new_adir = ".arctica\-$the_sanetized_username\-$the_random_dirtail";
	unless (-d "$the_tmp_dir/$potential_new_adir") {
		mkdir("$the_tmp_dir/$potential_new_adir") 
			or die("Unable to create '$the_tmp_dir/$potential_new_adir'");
		permZealot("$the_tmp_dir/$potential_new_adir");

		mkdir("$the_tmp_dir/$potential_new_adir/cli") 
			or die("Unable to create '$the_tmp_dir/$potential_new_adir/cli'");
		permZealot("$the_tmp_dir/$potential_new_adir/cli");

		mkdir("$the_tmp_dir/$potential_new_adir/ses") 
			or die("Unable to create '$the_tmp_dir/$potential_new_adir/ses'");
		permZealot("$the_tmp_dir/$potential_new_adir/ses");

		mkdir("$the_tmp_dir/$potential_new_adir/con") 
			or die("Unable to create '$the_tmp_dir/$potential_new_adir/con'");
		permZealot("$the_tmp_dir/$potential_new_adir/con");

		mkdir("$the_tmp_dir/$potential_new_adir/soc") 
			or die("Unable to create '$the_tmp_dir/$potential_new_adir/soc'");
		permZealot("$the_tmp_dir/$potential_new_adir/soc");
		mkdir("$the_tmp_dir/$potential_new_adir/soc/local/") 
			or die("Unable to create '$the_tmp_dir/$potential_new_adir/soc/local/'");
		permZealot("$the_tmp_dir/$potential_new_adir/soc/local/");
		mkdir("$the_tmp_dir/$potential_new_adir/soc/remote/") 
			or die("Unable to create '$the_tmp_dir/$potential_new_adir/soc/remote/'");
		permZealot("$the_tmp_dir/$potential_new_adir/soc/remote/");
		mkdir("$the_tmp_dir/$potential_new_adir/soc/remote/in/") 
			or die("Unable to create '$the_tmp_dir/$potential_new_adir/soc/remote/in/'");
		permZealot("$the_tmp_dir/$potential_new_adir/soc/remote/in/");
		mkdir("$the_tmp_dir/$potential_new_adir/soc/remote/out/") 
			or die("Unable to create '$the_tmp_dir/$potential_new_adir/soc/remote/out/'");
		permZealot("$the_tmp_dir/$potential_new_adir/soc/remote/out/");

		BugOUT(8,"create_new_adir: all seems ok, returning '$potential_new_adir'");
		return $potential_new_adir;
	} else {
		die("Realizing '$the_tmp_dir/$potential_new_adir' already exist?!");
	}
	
	BugOUT(9,"Unexpected end of 'create_new_adir'");
}

sub check_for_rtail_dir {
	my $check_in_dir = $_[0];
	my $the_sanetized_username = make_sane_userdir_name();

	if (-d $check_in_dir) {
		my @potential_dirs;
		my $dir_to_use;
		opendir(CHKDIR, $check_in_dir)
			or die("could not read \"$check_in_dir\"");
		while (readdir(CHKDIR)) {
			my $chk_dir = $_;
			if (-d "$check_in_dir/$chk_dir") {
				if ($chk_dir =~ /^\.arctica\-([a-zA-Z0-9\_]*)\-([a-zA-Z0-9]*)$/) {
					my $d_usrname = $1;
					my $d_rndtail = $2;
					if ($the_sanetized_username eq $d_usrname) {
						my $sanetized_dir_name
							= ".arctica-$d_usrname-$d_rndtail";
						if (user_owns_it("$check_in_dir/$sanetized_dir_name")) {
							push @potential_dirs,
								$sanetized_dir_name;
						} else {
							warn("check_for_rtail_dir: ",
								"wonky ownership of $sanetized_dir_name");
						}
					}

				} else {
				# ADD SOME DEBUGGING STUFF HERE?!
#					print "		POFS:	$_\n";
				}
			}
		}
		closedir(CHKDIR);
		
		my $pdircnt = @potential_dirs;
		my $pdmtime = 0; 
		if ($pdircnt > 0) {
			if ($pdircnt > 1) {
				warn("check_for_rtail_dir: more than one tmp dir?");
			}
			# Pick the one with highest mtime.... 
			foreach my $pdir (@potential_dirs) {
				$pdir =~ s/[\s\n]//g;
				if (-d "$check_in_dir/$pdir") {
					my $mtime = stat("$check_in_dir/$pdir")->mtime;
					if ($mtime > $pdmtime) {
						$pdmtime = $mtime;
						$dir_to_use = $pdir;
					}
				}
			}

			if (-d "$check_in_dir/$dir_to_use") {
				return $dir_to_use;
			} else {
				warn("check_for_rtail_dir: no existing dirs found!");
				return 0;
			}

		} else {
			warn("check_for_rtail_dir: no existing dirs found!");
			return 0;
		}
		
	} else {
		die("rtail check fail! This is not a dir: \"$check_in_dir\"");
	}
}


sub check_secure_permissions {
	my $the_path = $_[0];
	BugOUT(9,"check_secure_permissions for $the_path");
	$the_path =~ s/\n//g;
	if (user_owns_it($the_path)) {
		my $file_stat = stat($the_path);
		if (-f $the_path) {
			if ($file_stat->mode ne 33152) {
				warn("Insecure permissions for \"$the_path\" ",
					"(",$file_stat->mode,")\n");
				return 0;
			} else {
				return 1;
			}

		} elsif (-d $the_path) {
			if ($file_stat->mode ne 16832) {
				warn("Insecure permissions for \"$the_path\" ",
					"(",$file_stat->mode,")\n");
				return 0;
			} else {
				return 1;
			}

		} elsif (-S $the_path) {
			if ($file_stat->mode ne 49600) {
				warn("Insecure permissions for \"$the_path\" ",
					"(",$file_stat->mode,")\n");
				return 0;
			} else {
				return 1;
			}

		} else {
			warn("Failed to check permissions for \"$the_path\"!");
			return 0;
		}
	} else {
		return 0;
	}
}

sub user_owns_it {
	my $the_path = $_[0];
	$the_path =~ s/\n//g;
	BugOUT(9,"check user_owns_it $the_path");
	my $the_user = $_[1];
	if (-e $the_path) {
		unless ($the_user) {
			$the_user = $ENV{'USER'};
		}
		
		my $file_stat = stat($the_path);
		if (getpwuid($file_stat->uid) eq $the_user) {
			return 1;

		} else {
			warn("user_owns_it, $the_path is owned by ",
				getpwuid($file_stat->uid)," not $the_user !\n");
			return 0;

		}

	} else {
		warn("user_owns_it, can't find: $the_path !\n");
		return 0;
	}
}


sub make_sane_userdir_name {
	my $name = $ENV{'USER'};
	BugOUT(9,"make_sane_userdir_name for '$name'");
	$name =~ s/([^a-zA-Z0-9])/sprintf("_%x",ord($1))/egi;
	if ($name =~ /^([a-zA-Z0-9\_]*)$/) {
		$name = $1;
		return $name;
	} else {
		die("make_sane_userdir_name: sanitation of '$ENV{'USER'}/$name' FAILED!");
	}
}

1;
