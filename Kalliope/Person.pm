
#  Copyright (C) 1999-2001 Jesper Christensen 
#
#  This script is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License as
#  published by the Free Software Foundation; either version 2 of the
#  License, or (at your option) any later version.
#
#  This script is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this script; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#  Author: Jesper Christensen <jesper@kalliope.org>
#
#  $Id$

package Kalliope::Person;

use strict ('vars');
use Carp;
use Kalliope::DB ();
use Kalliope::Work ();
use Kalliope::Page ();
use Kalliope ();

my $dbh = Kalliope::DB->connect;

sub new {
    my ($class,%arg) = @_;
    my $sql;
    $sql = 'fhandle = "'.$arg{'fhandle'}.'"' if defined $arg{'fhandle'};
    $sql = 'fid = "'.$arg{'fid'}.'"' if defined $arg{'fid'};
    $sql = 'fid = "'.$arg{'id'}.'"' if defined $arg{'id'};
    confess "Need some kind of id to initialize a new person\n" unless $sql;
    my $sth = $dbh->prepare("SELECT * FROM  fnavne WHERE $sql");
    $sth->execute();
    my $obj = $sth->fetchrow_hashref;
    Kalliope::Page::notFound unless $obj;
    bless $obj,$class;
    return $obj;
}

# Class method
sub exist {
    my $fhandle = shift;
    my $sth = $dbh->prepare("SELECT fhandle FROM fnavne WHERE fhandle = ?");
    $sth->execute($fhandle);
    return $sth->rows;
}

sub fhandle {
    return $_[0]->{'fhandle'};
}

sub fid {
    return $_[0]->{'fid'};
}

sub hasPoems {
    return shift->{'vaerker'};
}

sub hasWorks {
    return shift->{'vers'};
}

sub lang {
    return shift->{'sprog'};
}

sub thumbURI {
    my $self = shift;
    return $self->{'thumb'} ? 'fdirs/'.$self->fhandle.'/thumb.jpg' : '';
}

sub hasBio {
    return $_[0]->{'bio'};
}

sub bio {
   my $self = shift;
   my $sth = $dbh->prepare("SELECT biotext FROM fnavne WHERE fid = ?");
   $sth->execute($self->fid);
   my $bio = $sth->fetchrow_array || '';
   $bio =~ s/<BR>/<BR>&nbsp;&nbsp;&nbsp;&nbsp;/gi;
   Kalliope::buildhrefs(\$bio);
   return $bio;
}

sub getDetailsAsHTML {
    return shift->{'detaljer'} || '';
}

sub lifespan {
   my $self = shift;
   my $return;
   if ($self->isUnknownPoet) {
      $return = '';
   } else {
      $return = "(".$self->yearBorn.'-'.$self->yearDead.')';
   }
   return $return;
}

sub yearBorn {
   return $_[0]->{'foedt'};
}

sub yearDead {
   return $_[0]->{'doed'};
}

sub isUnknownPoet {
   my $self = shift;
   return !($self->yearDead && $self->yearBorn);
}

sub sortString {
   return $_[0]->reversedName;
}

sub name {
   return $_[0]->fornavn.' '.$_[0]->efternavn;
}

sub fornavn {
   return shift->{'fornavn'} || '';
}

sub efternavn {
   return shift->{'efternavn'} || '';
}

sub reversedName {
   return $_[0]->efternavn.', '.$_[0]->fornavn;
}

sub bioURI {
    return 'ffront.cgi?fhandle='.$_[0]->fhandle;
}

sub worksURI {
    return 'fvaerker.pl?'.$_[0]->fhandle;
}

sub clickableTitle {
    return $_[0]->clickableNameGreen;
}

sub smallIcon {
     return '<IMG BORDER=0 HEIGHT=32 WIDTH=32 SRC="gfx/icons/poet-h48.gif">';
}

sub clickableNameBlack {
   my $self = shift;
   return '<A CLASS=black HREF="'.$self->bioURI.'">'.$self->name.'</A>';
}

sub clickableNameGreen {
   my $self = shift;
   return '<A CLASS=green HREF="'.$self->bioURI.'">'.$self->name.'</A>';
}

sub poemCount {
    my $self = shift;
    my $sth = $dbh->prepare("SELECT count(*) FROM digte WHERE fid = ? AND layouttype = 'digt' AND afsnit = 0");
    $sth->execute($self->fid);
    my ($count) = $sth->fetchrow_array;
    return $count;
}

sub concurrentPersons {

}

sub poeticalWorks {
    my $self = shift;
    my $sth = $dbh->prepare("SELECT vid FROM vaerker WHERE fid=? AND type='v' ORDER BY aar");
    $sth->execute($self->fid);
    my @list;
    while (my ($vid) = $sth->fetchrow_array) {
        push @list, new Kalliope::Work('vid' => $vid);
    }
    return @list;
}

sub proseWorks {
    my $self = shift;
    my $sth = $dbh->prepare("SELECT vid FROM vaerker WHERE fid=? AND type='p' ORDER BY aar");
    $sth->execute($self->fid);
    my @list;
    while (my ($vid) = $sth->fetchrow_array) {
        push @list, new Kalliope::Work('vid' => $vid);
    }
    return @list;
}

sub menu {
    my $self = shift;
    my $page = shift;
    my $poetName = $self->name;
    my %menuStruct = (
       forside => { url => 'ffront.cgi?', 
                    title => 'Forside', 
                    desc => "Tilbage til forsiden for $poetName",
                    status => 1 },
       vaerker => { url => 'fvaerker.pl?', 
                    title => 'V�rker', 
                    desc => "${poetName}s samlede poetiske v�rker",
                    status => $self->hasWorks },
       titlelines => { url => 'flines.pl?mode=1&', 
                    title => 'Digttitler', 
                    desc => "Vis titler p� alle digte",
                    status => $self->hasPoems },
       firstlines => { url => 'flines.pl?mode=0&', 
                    title => 'F�rstelinier', 
                    desc => "Vis f�rstelinier for samtlige digte",
                    status => $self->hasPoems },
       popular => { url => 'fpop.pl?', 
                    title => 'Popul�re', 
                    desc => "Top-10 over mest l�ste $poetName digte i Kalliope",
                    status => $self->hasPoems },
       prosa     => { url => 'fvaerker.pl?mode=prosa&', 
                    title => 'Prosa', 
	            desc => qq|${poetName}s prosatekster|,
                    status => $self->{'prosa'} },
       pics      => { url => 'fpics.pl?', 
                    title => 'Portr�tter', 
                    desc => "Portr�tgalleri for $poetName",
                    status => $self->{'pics'} },
       bio       => { url => 'biografi.cgi?', 
                    title => 'Biografi', 
                    desc => qq|En kortfattet introduktion til ${poetName}s liv og v�rk|,
                    status => $self->hasBio },
       samtidige => { url => 'samtidige.cgi?', 
                    title => 'Samtid', 
                    desc => qq|Digtere som udgav v�rker i ${poetName}s levetid|,
                    status => !$self->isUnknownPoet},
       henvisninger => { url => 'henvisninger.cgi?', 
                    title => 'Henvisninger', 
                    desc => 'Oversigt over tekster som henviser til '.$poetName.'s tekster.',
                    status => 1 },
       links     => { url => 'flinks.pl?', 
                    title => 'Links', 
                    desc => 'Henvisninger til andre steder p� internettet, som har relevant information om '.$poetName,
                    status => $self->{'links'} },
       primaer   => { url => 'fsekundaer.pl?mode=p&', 
                    title => 'Prim�r', 
                    desc => 'Henvisninger til '.$poetName.'s prim�rlitteratur',
		    status => $self->{'primaer'} },
       sekundaer => { url => 'fsekundaer.pl?mode=s&', 
                    title => 'Sekund�r', 
                    desc => 'Henvisninger til sekund�rlitteratur om '.$poetName,
		    status => $self->{'sekundaer'} } );
    my @keys = qw/forside vaerker titlelines firstlines popular prosa pics bio samtidige henvisninger links primaer sekundaer/;
    my $HTML;
    my @itemsHTML;
    foreach my $key (@keys) {
        my %item = %{$menuStruct{$key}};
        my $url = $item{url}.'fhandle='.$self->fhandle;
        my $title = $key eq $page->{'page'} ?
                    '<b>'.$item{'title'}.'</b>' :
                    $item{'title'};
        push @itemsHTML, qq|<A CLASS="white" TITLE="$item{desc}" HREF="$url">$title</A>| if $item{status};
    }
    $HTML = join ' <span class="lifespan">&#149;</span> ',@itemsHTML;
    return $HTML;
}

sub getSearchResultEntry {
    my ($self,$escapedNeedle,@needle) = @_;
    my $content = $self->name;

    foreach my $ne (@needle) {
	$content=~ s/($ne)/\n$1\t/gi;
    }
    $content =~ s/\n/<B>/g;
    $content =~ s/\t/<\/B>/g;
    
    my $HTML = '<IMG ALT="Digter" ALIGN="right" SRC="gfx/icons/poet-h48.gif">';
    $HTML .= '<A CLASS=blue HREF="ffront.cgi?fhandle='.$self->fhandle.qq|">|.$content.qq|</A><BR>|;
    $HTML .= '<SPAN STYLE="color: #a0a0a0">'.$self->lifespan."</SPAN><BR><BR>";
    return $HTML;
}


1;
