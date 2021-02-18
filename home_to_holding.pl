#!/usr/bin/perl

#  This script loops through each overdue item, determines the fine,
#  and updates the total amount of fines due by each user.  It relies on
#  the existence of /tmp/fines, which is created by ???
# Doesnt really rely on it, it relys on being able to write to /tmp/
# It creates the fines file
#
#  This script is meant to be run nightly out of cron.

# Copyright 2000-2002 Katipo Communications
# Copyright 2011 PTFS-Europe Ltd
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use Modern::Perl;

use Getopt::Long;

use C4::Context;
use C4::Items;
use Koha::Item;

my $help;
my $verbose;
my $confirm;

GetOptions(
    'h|help'    => \$help,
    'v|verbose' => \$verbose,
    'c|confirm' => \$confirm,
);
my $usage = << 'ENDUSAGE';

This script updates all item's homebranches to be the item's holdingbranch

This script has the following parameters :
    -h --help: this message
    -v --verbose
    -c --confirm

ENDUSAGE

if ($help) {
    print $usage;
    exit;
}

my $dbh = C4::Context->dbh();
my $query = "
    SELECT biblionumber, itemnumber, holdingbranch, homebranch FROM items WHERE homebranch != holdingbranch
    AND !( itype = 'PER' AND ccode = 'MAG')
    AND !( itype = 'YM'  AND ccode = 'MAG')
    AND !( itype = 'LIT' AND ccode = 'LIT')
    AND itype != 'MOBBOOK'
    AND itype != 'MOBCD'
    AND itype != 'QRBOOK'
";
my $sth = $dbh->prepare( $query );
$sth->execute();

while ( my $item = $sth->fetchrow_hashref() ) {
    my $biblionumber = $item->{biblionumber};
    my $itemnumber = $item->{itemnumber};
    my $holdingbranch = $item->{holdingbranch};
    my $homebranch = $item->{homebranch};

    print "Itemnumber: $itemnumber, Holding: $holdingbranch, Home: $homebranch\n" if $verbose;

    ModItem({ homebranch => $holdingbranch }, $biblionumber, $itemnumber) if $confirm;
}
