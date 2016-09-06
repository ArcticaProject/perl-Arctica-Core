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
package Arctica::Core::eventInit;
use strict;
use Exporter qw(import);
use Arctica::Core::Basics qw( aex_initNameClassVersion genARandom arcticaAArt);
use Arctica::Core::BugOUT::Basics qw( BugOUT bugOutCfg BugOUT_dumpObjects );
use Arctica::Core::ManageDirs;
use Data::Dumper;
use Glib 'TRUE', 'FALSE';
# Be very selective about what (if any) gets exported by default:
our @EXPORT = qw();
# And be mindful of what we let the caller request, too:
our @EXPORT_OK = qw( genARandom BugOUT BugOUT_dumpObjects );

$ENV{'PATH'} = "";
my $SELF;

sub new {
	unless ($SELF) {
		my ($className,$theRest) = @_;
		my $ACF_self = {	
			dummydata => {
				somevalue	=> 12,
				otherinfo	=> "The Other INFO!",
			},
			isArctica => 1,
		};

		$ACF_self->{'AExecDeclaration'} = {
					aex_initNameClassVersion($theRest)};
		$ACF_self->{'BugOUT'} = Arctica::Core::BugOUT::Basics->new({
				'aexid' => $ACF_self->{'AExecDeclaration'}{'self_aID'},
			});
#		bugOutCfg(undef,'set','aexid',$ACF_self->{'AExecDeclaration'}{'self_aID'});
		$ACF_self->{'a_dirs'} = Arctica::Core::ManageDirs->new();
		BugOUT_dumpObjects($ACF_self);
		# pick one of the above.... DONT KEEP BOTH!!

		$ACF_self->{'Glib'}{'MainLoop'} = Glib::MainLoop->new;
		bless ($ACF_self, $className);

		# DO SOMETHING ELSE TO TIE INDIVIDUAL SIGNALS TO RESPECTIVE FUNCTIONS
		@SIG{qw( INT TERM HUP )} = sub {doSelfTerminate($_[0],$ACF_self);};
		$SELF = \$ACF_self;
		return $ACF_self;
	} else {
		die("Don't initiate ACF more than once!");
	}
}

sub append_aobject {
	my $aco = $_[0];
	my $to_append = $_[1];
	if ($to_append->{'isArctica'} and $to_append->{'aobject_name'}) {
		unless ($aco->{$to_append->{'aobject_name'}}) {
			$aco->{$to_append->{'aobject_name'}} = $to_append;
		} else {
			die "Don't append an Arctica object more than once!";
		}
	} else {
		die "Not an Arctica object?!";
	}
}


sub return_self {
	return  $SELF;
}


################################################################################
# This sub, should try to clean things up as much as posible.
sub doSelfTerminate {
	my $signal = $_[0];
	my $ACF_self = $_[1];
	BugOUT(2,"Self-terminating... ($signal)");
	$ACF_self->{'Glib'}{'MainLoop'}->quit;
	return 0; 
}
# THE END
################################################################################

1;
