=head1 ClearCase.pm

Object orientated interface to ClearCase.

=head1 Overview

This module tries to provide an Object Orientated interface to ClearCase, in particular targetted
to make it easier to write triggers and hooks.  Unfortunately, ClearCase is huge and life is short,
so there are some parts that are not covered (though they may be in future versions):

=over

=item

any administrative functionality e.g. checkvob

=item

any graphical interfaces, including CCRC

=item

snapshot views

=item

any functionality that is never used by end-users, e.g. element type management

=item

functionality that produces mostly textual output instead of object information, e.g. annotate or diff

=item

anything with a complicated interface that would be easier to call directly with ct()

=item

Most Windows functionality

=item

merge arrows are handled as hlinks, which is what they really are, so there is no support for e.g. rmmerge
=back

Everything is done through a ClearCase object, which you will get like this...

  my $cc = new ClearCase;

This object really represents the registry, and it has methods for getting view objects, vob objects,
region objects, etc.  Significant parts of the class hierarchy are:

  ClearCase
    ClearCase::Region*
    ClearCase::CurrentRegion
    ClearCase::Host*
    ClearCase::Vob*
      ClearCase::AtType*
      ClearCase::BrType*
      ClearCase::HlType*
      ClearCase::LbType*
      ClearCase::Trigger*
      ClearCase::TrType*
    ClearCase::ProjectVob*
      ClearCase::Component*
      ClearCase::Folder*
        ClearCase::Project*
          ClearCase::Stream*
            ClearCase::StreamComponent*
              ClearCase::Baseline*
                ClearCase::Activity*
                  ClearCase::Version*
    ClearCase::View*
      ClearCase::Checkout*
    ClearCase::CurrentView

These classes also exist, but don't fit neatly into the hierarchy:

    ClearCase::Attribute
    ClearCase::Branch
    ClearCase::Cleartool - runs a cleartool command
    ClearCase::ConfigRecord
    ClearCase::DerivedObject
    ClearCase::Element
    ClearCase::Hlink
    ClearCase::Label
    ClearCase::Lock
    ClearCase::Path

For details of what object types have other object types, look at the documentation for each class.
There are many other internal classes, but these are the classes that you need to be aware of if you're
going to use this module.

There are some general principles covering most or all of the external interfaces of the classes.

Accessors are simple methods.  To find the name of something, use the method name():

   print "Current view name is ",$cc->cwv->name,"\n";

Sets of things are typically accessed by two methods.  For example, $cc->vobs() will return a list
of ClearCase::Vob objects, while $cc->vob($vobtag) will return a single ClearCase::Vob object.

Modifiers or actions are typically modelled very closely on the underlying cleartool command.
For example, $cc->mkview() takes exactly the same options and arguments as 'cleartool mkview'.
This is in order to avoid having slightly different interfaces - if you know the -host -hpath -gpath
triplet for ct mkview, you'll know it for $cc->mkview(), and you can use the standard Rational
documentation for both:

  $cc->mkview(-tag=>$viewtag,"$storage/$viewtag.vws");

On the other hand, some actions take a subset of options or even no options at all; for example to remove a view, use
the ClearCase::View::rmview() method, e.g.

  my $cc = new ClearCase;
  my $view = $cc->view($viewtag);
  $view->rmview();

rmview() can get the view tag from the object, and it knows to use the -force option.  Each method's
documentation will indicate how to find out what flags and options are available.

Most action methods can also take a hash reference, which specifies the return values wanted.
The values are the same values that can be passed to forkexec(), e.g. to run mkview, getting
stdout and stderr instead of letting them print out, use this:

  my ($status,$stdout,$stderr) = $cc->mkview({leaveStdout=>0,leaveStderr=>0},-tag=>$viewtag,"$storage/$viewtag.vws");

The hash can be anywhere in the argument list, but by convention it should be first.  By default, stdout and stderr are left alone, i.e. they go to stdout and stderr, and the status is returned.

The environment variable CLEARCASE_MODULE_VERBOSE can be set - this will print out cleartool commands and the exit status.

The environment variable CLEARCASE_MODULE_DEBUG can also be set - this will print out the same as CLEARCASE_MODULE_VERBOSE, plus any stdout or stderr that is being captured.

Filesystem or view objects are represented by ClearCase::Path objects.  A ClearCase::Path object really just contains
a path, possibly a view-extended path, which can reference (among other things):
- a version
- a branch
- an element
- a view-private file
- a checked-out file
- a file that is not in a vob

A ClearCase::Path doesn't have many methods and is not very useful; use the object() method to convert it into
a ClearCase::Version, ClearCase::Branch or ClearCase::Element as appropriate.  Be warned that the ClearCase::Path can become invalid if changes are made to the view - for example if the config spec is changed, or directories are updated.

=head1 Caveats

=over

=item

rename() does not update hashes and other data structures.  It probably should, but
it is only used rarely and it would be a lot of code spread across a lot of the module
to properly maintain.  Instead, simply create a new ClearCase object after using rename().

=item

the command line lets you operate on multiple things, e.g. move a bunch of files to a new
directory; the OO interface of this module means that you can only operate on one object at
a time.

=item

global types are not supported, though they may be in the future.

=item

string attributes have the quotes automatically added when setting and stripped when reading.

=item

You get a ClearCase::Version through a view or an activity, though the version does not belong
to the view or activity.  You can get a ClearCase::Checkout through a view too, and the
checkout does belong to the view.  Checkouts can only be done for the current
working view, though if a file is already checked out in another view you can
get the ClearCase::Checkout object for it.

=back

=head1 BUGS

None at the moment, though I'm sure there are plenty.  In particular there are lots of parts not implemented.

=head1 TODO

=over

=item

Need to support vtree operations, including support for ClearCase::Branch and ClearCase::Element -
currently there is just very limited support for ClearCase::Version.

=item

Add aliases() method to View & Vob - returns list of entries in other regions for same view/vob

=item

Fill out ClearCase::Checkout->comment()

=item

Get rename() to update all data structures

=item

Test suite!

=item

Baseline management, including rmbl

=back

=head1 Future enhancements

=over

=item

maybe add ClearCase::Event, and add methods to use lshistory to get a list of events

=item

mastership transfer

=item

UCM baseline support should be a lot better

=item

 May be supported:
 Moving versions from one activity to another
 chactivity -cqaction
 chbl
 chproject
 chstream
 chview
 cptype
 deliver
 getcache
 ls   Use ct()
 lslock
 protect oid: as soon as I work out what this is...
 reserve -cact
 unco -cact
 unreserve -cact
 scrubber

 Should be added in an upcoming version:
 anything to do with replicas
 lock  Probably will be added, but needs to be added to a lot of different classes
 mkbl
 rmbl
 rmbranch
 rmver
 space
=back

=head1 Missing functionality

 anything to do with replicas
 catcr -select
 all CCRC
 xclearcase settings or any graphical interface
 file typing
 checkvob
 chevent
 chflevel
 chmaster
 chpool
 chtype
 clearaudit
 clearbug
 cleardescribe
 cleardiff
 cleardiffbl
 clearexport_...
 clearfsimport
 clearhistory
 clearimport
 clearjoinproj
 clearlicense
 clearmake
 Merging
 clearviewupdate
 creds
 crmregister
 diff
 diffbl
 diffcr
 dospace
 du_tool
 exporting VOBs
 file
 find
 findmerge
 get
 getlog
 help
 lsclients
 lshistory
 lspool
 lssite
 lsstgloc
 lsvtree (though you can get this with versions, branches & elements)
 man
 merge
 mkattr -config do-name
 mkeltype
 mklabel -config do-name
 mkpool
 mkproject -template
 mkregion
 mkstgloc
 mkstream -integration-template
 mvfsstorage
 mvfsversion
 omake
 promote_server
 protect eltype:
 protect pool:
 protectvob
 pwd
 rebase (use cleartool rebase directly)
 recoverview
 reformatview
 reformatvob
 relocate
 rename eltype
 rename pool
 rename oid
 reqmaster -acl | -enable | -disable | -deny | -allow
 rgy_backup
 rgy_check
 rgy_passwd
 rgy_switchover
 rmdo -all | -zero
 rmmerge - use rmhlink instead
 rmpool
 rmproject -template
 rmregion
 rmstgloc
 rmtag -all
 rmtype eltype:
 rmview -uuid -avobs | -all
 schedule
 setcache
 setplevel
 setrgysvrtype
 setsite
 setview  - you must already be in a view!
 update
 utfxxcleardiffmerge
 view_scrubber
 vob_scrubber
 vob_sidwalk
 vob_siddump
 vob_snapshot
 vob_snapshot_setup
 winkin
 xclearcase
 xcleardiff
 xmldiffmrg

=head1 Classes

A few quick notes on method documentation: each method shows the arguments and return type.  An empty
argument list is shown as ().

The return type may not be exactly correct, for example cwv() actually returns a ClearCase::CurrentView
object, but this class inherits from - and can be treated the same as - ClearCase::View.  These details
may change in the future.  If you want to determine the class, use the documented return type and the
isa() method.

=cut 

use warnings;
use strict;

require 5.8;   # Needs Memoize

# Pre-declare all packages
package ClearCase;
package ClearCase::Activity;
package ClearCase::ActivityCollection;
package ClearCase::Attribute;
package ClearCase::AttributeMixin;
package ClearCase::AtType;
package ClearCase::AtTypeCollection;
package ClearCase::Baseline;
package ClearCase::BaselineCollection;
package ClearCase::Branch;
package ClearCase::BrType;
package ClearCase::BrTypeCollection;
package ClearCase::Checkout;
package ClearCase::Cleartool;
package ClearCase::Collection;
package ClearCase::Component;
package ClearCase::ConfigRecord;
package ClearCase::CurrentRegion;
package ClearCase::CurrentView;
package ClearCase::DerivedObject;
package ClearCase::DirectoryElement;
package ClearCase::DirectoryVersion;
package ClearCase::Element;
package ClearCase::FlatConfigRecord;
package ClearCase::Folder;
package ClearCase::FolderCollection;
package ClearCase::Hlink;
package ClearCase::HlType;
package ClearCase::HlTypeCollection;
package ClearCase::Host;
package ClearCase::HostCollection;
package ClearCase::Label;
package ClearCase::LbType;
package ClearCase::LbTypeCollection;
package ClearCase::Lock;
package ClearCase::LockMixin;
package ClearCase::Path;
package ClearCase::Project;
package ClearCase::ProjectVob;
package ClearCase::ProjectVobCollection;
package ClearCase::ProjectVobThingMixin;
package ClearCase::ProtectMixin;
package ClearCase::RecurseConfigRecord;
package ClearCase::Region;
package ClearCase::RegionCollection;
package ClearCase::RenameMixin;
package ClearCase::ReqmasterMixin;
package ClearCase::Stream;
package ClearCase::StreamCollection;
package ClearCase::Thing;
package ClearCase::Trigger;
package ClearCase::TriggerMixin;
package ClearCase::TrType;
package ClearCase::TrTypeCollection;
package ClearCase::Type;
package ClearCase::TypeCollection;
package ClearCase::UnionConfigRecord;
package ClearCase::Version;
package ClearCase::View;
package ClearCase::ViewCollection;
package ClearCase::ViewThingMixin;
package ClearCase::Vob;
package ClearCase::VobCollection;
package ClearCase::VobThingMixin;


###############################################################################
package ClearCase;

=head1 ClearCase

Provides an OO interface to all ClearCase artifacts.  Effectively represents
the registry.

Inherits from ClearCase::Thing

=cut


our @ISA = qw(ClearCase::Thing);

# Class variable - see the description above
our $VERBOSE = $ENV{CLEARCASE_MODULE_VERBOSE} || 0;
our $DEBUG = $ENV{CLEARCASE_MODULE_DEBUG} || 0;

use Memoize;

=head2 new() -> ClearCase

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{hosts} = new ClearCase::HostCollection $self;
    $self->{regions} = new ClearCase::RegionCollection $self;
    return $self;
}

#######################################
#-- ACCESSORS

# Internal method that everybody can use to get the top object
sub cc { return $_[0] }

=head2 rgy_host() -> string

Returns the hsotname of the registry host, taken from rgy_hosts.conf.
This doesn\'t return a ClearCase::Host, since there is no requirement
that the registry server be a ClearCase-configured system.

=cut

sub rgy_host {
    my @paths = qw(/var/adm/atria/config/rgy_hosts.conf);  # In future can expand to a list
                                                           # of possible locations

    my $rgy_host;
    foreach (@paths) {
        -f $_ or next;
        open F, $_ or die "Cannot open $_, $!\n";
        chomp($rgy_host = <F>);
        close F;
    }
    die "Cannot find rgy_host\n" unless $rgy_host;
    return $rgy_host;
}

=head2 regions() -> ( ClearCase::Region,... )

=cut

sub regions { $_[0]->{regions}->getAll() }

=head2 region(regionName,...) -> ClearCase::Region,...

=cut

sub region  { my $self = shift; $self->{regions}->getOne(@_) }

# These are all delegated to the currentRegion

=head2 vobs() -> ( ClearCase::Vob,... )

=cut

sub vobs  { $_[0]->currentRegion->vobs }

=head2 vob(vobName) -> ClearCase::Vob

=cut

sub vob   { $_[0]->currentRegion->vob($_[1]) }

=head2 pvobs() -> ClearCase::ProjectVob

=cut

sub pvobs { $_[0]->currentRegion->pvobs() }

=head2 pvob(pvobName) -> ClearCase::ProjectVob

=cut

sub pvob  { $_[0]->currentRegion->pvob($_[1]) }

=head2 views() -> ( ClearCase::View,... )

=cut

sub views { $_[0]->currentRegion->views() }

=head2 view(viewName) -> ClearCase::View

=cut

sub view  { $_[0]->currentRegion->view($_[1]) }

=head2 host(hostname,...) -> ClearCase::Host,...

Note there is no hosts() method - the complete list of
hosts is not easily gotten nor is it useful.

=cut

sub host { my $self = shift; $self->{hosts}->getOne(@_) }

=head2 currentRegion() -> ClearCase::Region

=cut

sub currentRegion {
    my $self = shift;
    $self->{currentRegion} ||= _get ClearCase::CurrentRegion $self, {};
}

=head2 cwv() -> ClearCase::View

=cut
    
sub cwv {
    my $self = shift;
    $self->{cwv} ||= _get ClearCase::CurrentView $self, {};
}

=head2 pwv() -> ClearCase::View

A synonym for cwv()

=cut
    
# This is how you create a second name for the same method
*pwv = \&cwv;

=head2 currentHost() -> ClearCase::Host

=cut

sub currentHost {
    my $self = shift;
    return $self->{hosts}->getCurrent;
}

=head2 find(<ct find options>) -> ClearCase::Path*

The find() method takes the same selection options as cleartool find, but it does not take any action options,
i.e. -print, -exec or -ok.  It returns a list of ClearCase::Path objects which contain strings - to
convert these to ClearCase::Element, ClearCase::Branch or ClearCase::Version objects use the object() method.

=cut

sub find {
    my $self = shift;
    my $cmd = new ClearCase::Cleartool (
					'find',
					-avobs => '',
					-all => '',
					-visible => '',
					-nvisible => '',
					-name => 's',
					-depth => '',
					-nrecurse => '',
					-directory => '',
					-cview => '',
					-user => 's',
					-group => 's',
					-type => 's',
					-follow => '',
					-nxname => '',
					-element => 's',
					-branch => 's',
					-version => 's',
					-kind => 's',
					);

    $cmd->prepare(@_, { returnFail=>1, leaveStdout=>0 } );
    #$cmd->setArgs(-exec=>'echo  $CLEARCASE_XPN ');
    $cmd->setArgs('-print');
    $cmd->run();

    return map { _get ClearCase::Path $_ } @{($cmd->retval)[1]};
    
}

=head2 path(string) -> ClearCase::Path

Converts a string containing a path into an object.  To get the element,
version or branch as appropriate use the object() method on the returned object,
e.g.
my $dirVersion = $cc->path('/vobs/OS/topdir')->object;

=cut

sub path { _get ClearCase::Path @_ }

#######################################
#-- OPERATORS

=head2 mkview(<ct mkview options and arguments>) -> ClearCase::View | undef

This method passes arguments and options through to cleartool mkview, with the following
optional modifications:

=over

=item -region

Can be a ClearCase::Region

=item -stream

Can be a ClearCase::Stream

=item -host

Can be a ClearCase::Host

=back

For example:

  my $view = $cc->mkview(-tag=>$viewtag,
                         -host=>$cc->currentHost,
                         -hpath=>"$viewdir/$viewtag.vws",
                         -gpath=>"$viewdir/$viewtag.vws",
                         -region=>'ma35unix02',
                         "$viewdir/$viewtag.vws");

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mkview {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'mkview',
					-tag => 's',
					-tcomment => 's',
					-tmode => 's',
					-region => 'ClearCase::Region',
					-stream => 'ClearCase::Stream',
					-ln => 's',
					-ncaexported => 's',
					-cachesize => 's',
					-shareable_dos => '',
					-nshareable_dos => '',
					-stgloc => 's',
					-host => 'ClearCase::Host',
					-hpath => 's',
					-gpath => 's',
					-snapshot => '',
					-vws => 's',
					);

    $cmd->prepare(@_);
    $cmd->run();
    
    return $cmd->retval unless $cmd->status;

    # Add the view tag to the correct region
    my $region = $cmd->opt('-region') || $self->currentRegion;

    # If region was just a string, convert it to a Region object
    if (!ref $region) {
	$region = $self->region($region);
    }

    $region->{views}->add($cmd->opt('-tag'));

    return $cmd->retval($region->view($cmd->opt('-tag'))) if defined wantarray;
}

=head2 mkvob(<ct mkvob options and arguments>) -> ClearCase::Vob | undef

This method passes arguments and options through to cleartool mkvob, with the following
optional modifications:

=over

=item -region

Can be a ClearCase::Region

=item -host

Can be a ClearCase::Host

=back

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mkvob {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'mkvob',
					-tag => 's',
					-comment => 's',
					-tcomment => 's',
					-region => 'ClearCase::Region',
					-options => 's',
					-ncaexported => '',
					-public => '',
					-password => 's',
					-nremote_admin => '',
					-host => 'ClearCase::Host',
					-hpath => 's',
					-gpath => 's',
					-stgloc => 's',  # can be -auto
					);

    $cmd->prepare(@_);
    $cmd->run();

    return $cmd->retval unless $cmd->status;

    # Add the vob tag to the correct region
    my $region = $cmd->opt('-region') || $self->currentRegion;

    # If region was just a string, convert it to a Region object
    if (!ref $region) {
	$region = $self->region($region);
    }

    $region->{vobs}->add($cmd->opt('-tag'));

    return $cmd->retval($region->vob($cmd->opt('-tag'))) if defined wantarray;
}

=head2 mountAll() -> 0 | 1

=cut

sub mountAll {
    # Mount all vobs
    my $self = shift;
    my ($status) = $self->ct(['mount','-all'],returnFail=>1,leaveStdout=>1,leaveStderr=>1);
    return ($status == 0);
}

=head2 register(<ct register options and arguments>) -> 0 | 1

This doesn\'t change the list of view or vob tags.  -host can be passed a ClearCase::Host object.

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub register {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'register',
					-view => '',
					-vob => '',
					-replace => '',
					-host => 'ClearCase::Host',
					-hpath => 's',
					-ucmproject => '',
					);
    $cmd->prepare(@_);
    $cmd->run();

    return $cmd->retval;
}

###############################################################################

=head1 ClearCase::Activity

Inherits from ClearCase::Thing, ClearCase::TriggerMixin, ClearCase::RenameMixin, ClearCase::AttributeMixin

=cut

package ClearCase::Activity;

use Text::ParseWords qw(quotewords);

our @ISA = qw(ClearCase::Thing ClearCase::ProjectVobThingMixin ClearCase::TriggerMixin ClearCase::RenameMixin ClearCase::AttributeMixin);

# Versions is apparently expensive to get, and slows down the lsactivity command significantly, so only get it if explicitly requested
sub format { 'Name: %n\nOwner: %o\nLocked: %[locked]p\nContrib Activities: %[contrib_acts]p\nCQ Record Id: %[crm_record_id]p\nCQ Record Type: %[crm_record_type]p\nState: %[crm_state]p\nHeadline: %[headline]p\nName Resolver View: %[name_resolver_view]p\nStream: %[stream]p\nView: %[view]p\n\n' }

#######################################
#-- ACCESSORS

=head2 name() -> string

=cut

sub name { return $_[0]->{Name} }

=head2 specifier() -> string

Returns the name of the activity in the form 'activity:<name>@<vob>'

=cut

sub specifier {
    my $self = shift;
    return 'activity:'.$self->name.'@'.$self->pvob->name;
}

=head2 locked() -> 'locked' | 'unlocked' | 'obsolete'

=cut

sub locked { return $_[0]->{Locked} }

=head2 contrib_activities() -> ( ClearCase::Activity,... )

List of activities that contributed to the change set of an integration activity.

=cut

sub contrib_activities {
    my $self = shift;
    return $self->pvob->activity(split(' ',$self->{'Contrib Activities'}));
}

=head2 cq_record_id() -> string

=cut

sub cq_record_id { return $_[0]->{'CQ Record Id'} }

=head2 cq_record_type() -> string

=cut

sub cq_record_type { return $_[0]->{'CQ Record Type'} }

=head2 state() -> string

=cut

sub state { return $_[0]->{State} }

=head2 headline() -> string

=cut

sub headline { return $_[0]->{Headline} }

=head2 name_resolver_view() -> ClearCase::View

A "best guess" view for resolving the names of versions in the change set.

=cut

sub name_resolver_view { my $self = shift; return $self->cc->view($self->{'Name Resolver View'}) }

=head2 stream() -> ClearCase::Stream

=cut

sub stream { my $self = shift; return $self->pvob->stream($self->{Stream}) }

=head2 versions() -> ( ClearCase::Version,... )

This operation can take a long time, depending on the number of versions.

=cut

sub versions {
    my $self = shift;
    my ($stdout) = $self->ct(['describe','-fmt','%[versions]CQp\n',$self->specifier],returnFail=>0,leaveStdout=>0,leaveStderr=>1);
    my @versionNames = quotewords(', ',0,$stdout->[0]);

    my @versions;

    foreach (@versionNames) {
	push @versions, (_get ClearCase::Path $_)->object();
    }

    return @versions;
}

=head2 view() -> ClearCase::View

=cut

sub view { my $self = shift; return $self->cc->view($self->{View}) }

#######################################
#-- OPERATORS

=head2 rmactivity() -> 0 | 1

=cut

sub rmactivity {
    my $self = shift;

    my ($status) = 
	$self->ct(['rmactivity','-nc','-force',$self->specifier],leaveStdout=>1,leaveStderr=>1,returnFail=>1);
    return undef if $status != 0;

    $self->{parent}->forget($self->name);

    return 1;
}

###############################################################################
package ClearCase::ActivityCollection;

our @ISA = qw(ClearCase::Collection ClearCase::ProjectVobThingMixin);

sub _getCommand {
        # Different command depending on whether we want all or some items
    my $self = shift;
    my @names = @_;

    my @wanted;

    if (@names) {
	# Want just some items
	@wanted = map { "activity:$_\@".$self->vob->name } @names;
    } else {
	# Want all items
	@wanted = ('-invob',$self->vob->name);
    }

    return('lsactivity','-fmt',ClearCase::Activity->format,@wanted);
}

sub _nameField { 'Name' }

###############################################################################

=head1 ClearCase::Attribute

Inherits from ClearCase::Thing

=cut

package ClearCase::Attribute;

our @ISA = qw(ClearCase::Thing ClearCase::VobThingMixin);

#######################################
#-- CONSTRUCTOR
sub _get {
    my $class = shift;
    my $attype = shift;
    my $value = shift;
    my $parent = shift;

    return bless {
	attype => $attype,
	value => $value,
	parent => $parent,
    }, $class
}

#######################################
#-- ACCESSORS

=head2 attype() -> ClearCase::AtType

=cut

sub attype { $_[0]->{attype} }

=head2 value() -> string

=cut

sub value { $_[0]->{value} }

=head2 rmattr() -> 0 | 1

=cut

sub rmattr {
    my $self = shift;

    my ($status) = $self->ct(['rmattr',$self->attype->specifier,$self->parent->specifier],returnFail=>1,leaveStdout=>1,leaveStderr=>1);

    return ($status == 0);
}

    
###############################################################################

=head1 ClearCase::AttributeMixin

This class is inherited by all objects that represent things that can have attributes, e.g. vobs,
versions, etc.

=cut 

package ClearCase::AttributeMixin;

use Text::ParseWords qw(quotewords);

sub _getAttributes {
    my $self = shift;
    my ($stdout) = $self->ct(['describe','-fmt',"\%a",$self->specifier],keepStdout=>1,splitStdout=>0);
    $stdout =~ s/\((.*)\)/$1/;    # Strip brackets
    foreach my $a (quotewords(', ',1,$stdout)) {
	my ($k,$v) = split '=', $a;
	next if exists $self->{attribute}{$k};
	$self->{attribute}{$k} = _get ClearCase::Attribute $self->vob->attype($k), $v, $self;
    }
}

=head2 attributes() -> ( ClearCase::Attribute,... )

=cut

sub attributes {
    my $self = shift;
    $self->_getAttributes;
    return values %{$self->{attribute}};
}

=head2 attribute(attributeName,...) -> ClearCase::Attribute,...

=cut

# Getting attributes is cheap, so always get all attributes.
# Act like getOne with the return value.
sub attribute {
    my $self = shift;
    $self->_getAttributes;
    my @types = map { ref $_ ? $_->name : $_ } @_;

    if (defined wantarray and wantarray eq '' and @types == 1) {
	return $self->{attribute}{$types[0]};
    } else {
	return map { $self->{attribute}{$_} } @types;
    }
}

=head2 mkattr(<ct mkattr options and arguments>) value | undef

The attribute type argument or -default argument can be a ClearCase::AtType.
If the value is a string value, it must include quotes.

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mkattr {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'mkattr',
					-comment => 's',
					-replace => '',
					-recurse => '',
					-default => 'ClearCase::AtType',
					-pname => '',
					);
    $cmd->prepare(@_,$self);
    $cmd->run();

    return $cmd->retval unless $cmd->status;

    my $atType = $cmd->opt('-default') || ($cmd->args)[0];

    if (! ref $atType) {
	$atType = $self->vob->attype($atType);
    }

    return $cmd->retval($self->attribute($atType)) if defined wantarray;
}

###############################################################################

=head1 ClearCase::AtType

Inherits from ClearCase::Thing, ClearCase::ProtectMmixin, ClearCase::RenameMixin, ClearCase::LockMixin, ClearCase::Type

=cut

package ClearCase::AtType;
our @ISA = qw(ClearCase::Thing ClearCase::VobThingMixin ClearCase::ProtectMixin ClearCase::RenameMixin ClearCase::LockMixin ClearCase::Type);

sub format { 'Name: %n\nCreated: %d\nLocked: %[locked]p\nScope: %[type_scope]p\nMaster replica: %[master]p\nType mastership: %[type_mastership]p\nOwner: %u\n\n' }

sub kind { 'attype' }

#######################################
#-- ACCESSORS

=head2 name() -> string

=cut 

sub name { return $_[0]->{Name} }

=head2 created() -> string

=cut 

sub created { return $_[0]->{Created} }

=head2 locked() -> 'locked' | 'unlocked' | 'obsolete'

=cut 

sub locked { return $_[0]->{Locked} }

=head2 scope() -> 'ordinary' | 'global' | 'local copy'

=cut 

sub scope { return $_[0]->{Scope} }

=head2 masterReplica() -> string

In the future this will return a ClearCase::Replica object

=cut 

sub masterReplica { return $_[0]->{'Master replica'} }

=head2 typeMastership() -> 'shared' | 'unshared'

=cut 

sub typeMastership { return $_[0]->{'Type mastership'} }

=head2 owner() -> string

=cut 

sub owner { return $_[0]->{Owner} }

###############################################################################
package ClearCase::AtTypeCollection;

our @ISA = qw(ClearCase::TypeCollection);

###############################################################################

=head1 ClearCase::Baseline

Inherits from ClearCase::Thing, ClearCase::TriggerMixin, ClearCase::RenameMixin

=cut

package ClearCase::Baseline;

our @ISA = qw(ClearCase::Thing ClearCase::ProjectVobThingMixin ClearCase::TriggerMixin ClearCase::RenameMixin);

sub format { 'Name: %n\nPredecessor: %[predecessor]p\nCreated: %d\nOwner: %u\nLocked: %[locked]p\nActivities: %[activities]p\nStream: %[bl_stream]p\nComponent: %[component]p\n\n' }

=head2 name() -> string

=cut

sub name { $_[0]->{Name} }

=head2 specifier() -> string

Returns the name of the baseline in the form 'baseline:<name>@<vob>'

=cut

sub specifier {
    my $self = shift;
    return 'baseline:'.$self->name.'@'.$self->pvob->name;
}

=head2 created() -> string

=cut

sub created { $_[0]->{Created} }

=head2 owner() -> string

=cut

sub owner { $_[0]->{Owner} }

=head2 locked() -> 'locked' | 'unlocked' | 'obsolete'

=cut 

sub locked { $_[0]->{Locked} }

=head2 predecessor() -> ClearCase::Baseline

=cut 

sub predecessor {
    my $self = shift;
    $self->pvob->baseline($self->{Predecessor});
}

=head2 activities() -> ( ClearCase::Activity,... )

=cut

# Return list of activities in this baseline - do not cache anything
# since maintaining the list is not trivial.
sub activities {
    my $self = shift;
    return $self->pvob->activity($self->activityNames());
}

=head2 activityNames() -> ( string,... )

Return the short names of all activities for this baseline.  More efficient
than method activities() if all you want is the names.

=cut

sub activityNames {
    my $self = shift;
    my ($stdout) = $self->ct(['describe','-fmt','%[activities]p\n', $self->specifier],returnFail=>0);
    my @activityNames = split(' ',$stdout->[0]);
    return @activityNames;
}

=head2 stream() -> ClearCase::Stream

=cut

sub stream { my $self = shift; $self->pvob->stream($self->{Stream}) }

=head2 component() -> ClearCase::Component

=cut

sub component { my $self = shift; $self->pvob->component($_[0]->{Component}) }

###############################################################################
package ClearCase::BaselineCollection;

our @ISA = qw(ClearCase::Collection ClearCase::ProjectVobThingMixin);

sub _getCommand {
        # Different command depending on whether we want all or some items
    my $self = shift;
    my @names = @_;

    my @wanted;

    if (@names) {
	# Want just some items
	@wanted = map { "baseline:$_\@".$self->vob->name } @names;
    } else {
	# Want all items
	@wanted = ('-invob',$self->vob->name);
    }

    return('lsbl','-fmt',ClearCase::Baseline->format,@wanted);
}

sub _nameField { 'Name' }

###############################################################################

=head1 ClearCase::Branch

Represents a branch.  Do not confuse this with ClearCase::BrType.

=cut

package ClearCase::Branch;
our @ISA = qw(ClearCase::Thing ClearCase::VobThingMixin ClearCase::LockMixin);

#######################################
#-- CONSTRUCTOR

sub _get {
    my $class = shift;
    my $oid = shift;
    my $version = shift;
    return bless {oid => $oid, version => $version}, $class;
}

###############################################################################

=head1 ClearCase::BrType

Inherits from ClearCase::Thing ClearCase::ProtectMixin ClearCase::RenameMixin ClearCase::LockMixin ClearCase::Type ClearCase::AttributeMixin

=cut

package ClearCase::BrType;

our @ISA = qw(ClearCase::Thing ClearCase::VobThingMixin ClearCase::ProtectMixin ClearCase::RenameMixin ClearCase::LockMixin ClearCase::Type ClearCase::AttributeMixin);

sub format { 'Name: %n\nCreated: %d\nLocked: %[locked]p\nScope: %[type_scope]p\nConstraint: %[type_constraint]p\nMaster replica: %[master]p\nReqmaster: %[reqmaster]p\nOwner: %u\n\n' }
sub kind { 'brtype' }

#######################################
#-- ACCESSORS

=head2 name() -> string

=cut

sub name { return $_[0]->{Name} }

=head2 created() -> string

=cut

sub created { return $_[0]->{Created} }

=head2 locked() -> 'locked' | 'unlocked' | 'obsolete'

=cut 

sub locked { return $_[0]->{Locked} }

=head2 scope() -> 'ordinary' | 'global' | 'local copy'

=cut 

sub scope { return $_[0]->{Scope} }

=head2 constraint() -> 'one version per element' | 'one version per branch'

=cut 

sub constraint { return $_[0]->{Constraint} }

=head2 masterReplica() -> string

=cut

sub masterReplica { return $_[0]->{'Master replica'} }

=head2 reqmaster() -> 'denied for all instances' | 'allowed for all instances' | 'denied for branch type' | 'allowed for branch type'

=cut

sub reqmaster { return $_[0]->{'Reqmaster'} }

=head2 owner() -> string

=cut

sub owner { return $_[0]->{Owner} }

###############################################################################
package ClearCase::BrTypeCollection;

our @ISA = qw(ClearCase::TypeCollection);

###############################################################################

=head1 ClearCase::Checkout

Inherits from ClearCase::Thing

=cut

package ClearCase::Checkout;

our @ISA = qw(ClearCase::Thing ClearCase::ViewThingMixin);

use Memoize;

our $format = 'Date time: %d\nStatus: %Rf\nPath: %n\nVersion: %Vn\nPredecessor: %f\nOwner: %u\nActivity: %[activity]p\n\n';

#######################################
#-- CONSTRUCTOR

sub _get {
    my $class = shift;
    my $view = shift;
    my $fields = shift;
    my $self = bless $fields,$class;
    $self->{view} = $view;
    return $self;
}

#######################################
#-- ACCESSORS

=head2 view() -> ClearCase::View

=cut 

sub view { my $self = shift; return $self->cc->view($self->{view}) }

=head2 path() -> string

=cut

sub path { return $_[0]->{Path} }

=head2 name() -> string

=cut

sub name { return $_[0]->{Path} }

=head2 versionString() -> string

=cut

sub versionString { return $_[0]->{Path} }

=head2 dateTime() -> string

=cut

sub dateTime { return $_[0]->{'Date time'} }

=head2 status() -> 'reserved' | 'unreserved'

=cut 

sub status { return $_[0]->{Status} }

=head2 predecessor() -> ClearCase::Version

=cut

memoize('predecessor');
sub predecessor {
    my $self = shift;
    return new ClearCase::Version $self, $self->{Predecessor};
}

=head2 comment() -> string

=cut

memoize('comment');
sub comment {
    my $self = shift;
    my ($stdout) = $self->ct(['setview','-exec','cleartool describe -fmt "%Nc" "'.$self->path.'"',$self->view->name],splitStdout=>0);
    return $stdout;
}

#######################################
#-- OPERATORS

=head2 checkin(<ct ci options>) -> 0 | 1

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub checkin {
    my $self = shift;
    
    my $cmd = new ClearCase::Cleartool (
					'checkin',
					-comment => 's',
					-keep => '',
					-rm => '',
					-identical => '',
					-activity => 's',
					);

    $cmd->prepare(@_);
    $cmd->setArgs($self->path);
    $cmd->run();

    return $cmd->retval;
}

=head2 reserve([-comment => "..."]) -> 0 | 1

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub reserve {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'reserve',
					-comment => 's',
					);

    $cmd->prepare(@_);
    $cmd->setArgs($self->path);
    $cmd->run();

    return $cmd->retval;
}

=head2 unreserve([-comment => "..."]) -> 0 | 1

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub unreserve {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'unreserve',
					-comment => 's',
					);

    $cmd->prepare(@_);
    $cmd->setArgs($self->path);
    $cmd->run();

    return $cmd->retval;
}


=head2 uncheckout(<ct unco options>) -> 0 | 1

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub uncheckout {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'unreserve',
					-keep => 's',
					-rm => 's',
					);

    $cmd->prepare(@_);
    $cmd->setArgs($self->path);
    $cmd->run();

    return $cmd->retval;
}

###############################################################################
package ClearCase::Cleartool;

use Scalar::Util qw(blessed);
use Carp qw(croak);

# Internal package, not part of the external interface
# To use:
# my $cmd = new ClearCase::Cleartool('command',option-spec,....);
# $cmd->prepare(@_);
# $cmd->run();
# return $cmd->retval;
# There are many other scenarios and paths through the methods - see
# the methods themselves for details

our @ISA = qw(ClearCase::Thing);

# OO interface to defining and executing a cleartool command

#######################################
# Constructor, takes cleartool command, plus list of option specifiers:
# -opt => ''   - boolean flag
# -opt => 's'   - string
# -opt => 'ClearCase::TypeName'  - can take a ClearCase::TypeName, extracts name automatically
sub new {
    my $class = shift;
    my $command = shift;
    my %spec = @_;

    return bless {
	command => $command,
	spec => \%spec,
	ctOpts => { leaveStdout=>1, leaveStderr=>1, returnFail=>1 },    # By default just return the status
    }, $class;
}

#######################################
# pass in arguments and options to be parsed
sub prepare {
    my $self = shift;

    my $command = $self->{command};

    my $gotComment;
    my %actual;     # Actual is hash from opt flag to value, value is undef if no arg
    my %original;   # Original is hash from opt flag to value, if the value was changed,
                    # e.g. if the value was an object which was changed to the object name
    my @args;

    while (@_) {
	my $opt = shift;

	if (ref $opt eq 'HASH') {
	    # If this is a hash then it is a list of options for ct()
	    $self->{ctOpts} = { %{$self->{ctOpts}}, %$opt };
	    next;
	}

	if ($opt !~ /^-/) {
	    # Got an argument
	    push @args, $opt;
	    next;
	}

	if ($opt eq '-comment') {
	    $gotComment = 1;
	}

	if (!exists $self->{spec}{$opt}) {
	    die "Internal error: ClearCase::Cleartool::prepare($command,...) called with undefined option $opt\n";
	}

	if ($self->{spec}{$opt} eq '') {
	    # Option does not take an argument
	    $actual{$opt} = undef;
	    next;
	}

	# Option takes an argument
	if (!@_) {
	    # No arguments left - a mistake!
	    die "Internal error: ClearCase::Cleartool::prepare($command,...) called with no argument for option $opt\n";
	}

	my $arg = shift @_;    # Get the option argument and validate it....

	if ($self->{spec}{$opt} eq 's') {
	    # Option takes a string argument
	    $actual{$opt} = $arg;
	    next;
	}

	# Option type is a class/package
	if (!ref($arg)) {
	    # If option arg is just a string, pass it through unchanged - don't validate,
	    # instead just assume it is a name, e.g. a region name
	    $actual{$opt} = $arg;
	    next;
	}

	if ($arg->isa($self->{spec}{$opt})) {
	    $original{$opt} = $arg;
	    # If option arg is of the right kind - use either the ->specifier() or ->name()
	    if ($arg->can('specifier')) {
		$actual{$opt} = $arg->specifier;
	    } elsif ($arg->can('name')) {
		$actual{$opt} = $arg->name;
	    } else {
		die "Internal error: ClearCase::Cleartool::prepare($command,... called with class that has no specifier() or name() method\n";
	    }
	    next;
	}

	die "Internal error: ClearCase::Cleartool::prepare($command,...: option $opt: needs $self->{spec}{$opt} but instead got $arg\n";
    }

    # Special case - if no comment, but there is a -comment in the spec, then pass in -nc
    if (exists $self->{spec}{-comment} and !$gotComment) {
	$actual{-nc} = undef;
    }

    # Convert all the arguments from object to name
    @args = map {
	if (ref $_ and blessed $_) {
	    if ($_->can('specifier')) { $_->specifier } else { $_->name };
	} elsif (ref $_) {
	    croak "Internal error: argument $_ passed to ClearCase::Cleartool::prepare, but it is not an object\n";
	} else {
	    $_;
	}
    } @args;
    $self->{args} = \@args;
    $self->{actual} = \%actual;
    $self->{original} = \%original;
}

#######################################
# Return the value for a specific option
sub opt {
    my $self = shift;
    my $opt = shift;

    return $self->{original}{$opt} if exists $self->{original}{$opt};
    return $self->{actual}{$opt} if exists $self->{actual}{$opt};
    return undef;
}

#######################################
# Set an option explicitly
sub setOpt {
    my $self = shift;
    my $opt = shift;
    my $value = shift;
    $self->{actual}{$opt} = $value
}
    
#######################################
# Return the list of arguments (as opposed to options)
sub args {
    my $self = shift;
    return @{$self->{args}};
}

#######################################
# Replace the arguments
sub setArgs {
    my $self = shift;
    $self->{args} = \@_;
}

#######################################
# Run the command itself
sub run {
    my $self = shift;

    my @arguments;
    while (my($opt,$arg) = each %{$self->{actual}}) {
	push @arguments, $opt;
	defined $arg and push @arguments, $arg;
    }

    push @arguments, @{$self->{args}};

    my @retval = $self->ct([ $self->{command}, @arguments ], %{$self->{ctOpts}});
    
    # Flip the status from sh-style to perl-style
    if ($self->{ctOpts}{returnFail}) {
	$retval[0] = ($retval[0] == 0);
    }

    $self->{retval} = \@retval;
}

#######################################
# Status in perl boolean, i.e. non-zero means success
sub status {
    my $self = shift;

    return undef unless exists $self->{retval};  # Return undef if not called yet

    if ($self->{ctOpts}{returnFail}) {
	return $self->{retval}[0];
    } else {
	# flags say to not return from ct() on failure, but we know that ct()
	# returned (i.e. it didn't die()), so we know the command succeeded.
	return 1;
    }
}

#######################################
# Return some subset of status, stdout, stderr, depending on what was asked for
# originally.
sub retval {
    my $self = shift;

    if (@_ and $self->{ctOpts}{returnFail}) {
	# If an argument was passed in, this should be used as the status
	# instead of the simple status.
	$self->{retval}[0] = $_[0];
    }

    if (wantarray) {
	# Expecting a list, so return whatever we got from ct()

	return @{$self->{retval}};

    } elsif (defined wantarray) {
	# Expecting a scalar, so return status
	return $self->status;
    }

    # In a 'void' context, so no need to return anything
}

###############################################################################
package ClearCase::Collection;

# Internal abstract parent class for collections

our @ISA = qw(ClearCase::Thing);

#######################################
#-- CONSTRUCTOR
# Returns an (initially empty) collection
# 
sub new {
    my $class = shift;
    my $parent = shift;
    (my $itemClass = $class) =~ s/Collection$//;
    bless {
	gotAll=>0,
	collection=>{},
	parent=>$parent,
	itemClass=>$itemClass,
    }, $class;
}

#######################################
# Customization subroutines
# Override these to change the details of how a particular Collection subclass
# gets information about its items.

# _getCommand should return a list - the command to get a list of the items
sub _getCommand { die "Must override _getCommand" }

# _splitGetCommandOutput takes the output from _getCommand as a single string
# and splits it into separate item details.
sub _splitGetCommandOutput {
    my $self = shift;
    my $stdout = shift;
    my @retval = split /^\s*$/m, $stdout;
    return @retval;
}

# _nameField returns the property that names the item in the hash returned by _unpack
sub _nameField { die "Must override _nameField to split output of _getCommand into entries" }

#######################################
# Internal methods

# Get some items' details and store them in the collection.
# If no item names are listed, get them all.
sub _getSome {
    my $self = shift;
    my @names = @_;

    my @selectCommand;
    my @gotten; # List of things that were requested

    if (@names) {
	# Only need to get things that are not already in the hash.
	# extract the short name from the middle of a specifier
	my @needed = grep { /^(.*?\:)?(.*?)(\@.*)?$/; !$_ || !exists $self->{collection}{$2} } @names;
	return unless @needed;
	@selectCommand = ( $self->_getCommand(@needed) );

    } elsif (!$self->{gotAll}) {
	# Haven't got everything yet but we want everything, so get it
	@selectCommand = $self->_getCommand;

    } elsif (%{$self->{pending}}) {
	# There are pending items that haven't been got yet, so get them
	@selectCommand = ( $self->_getCommand(keys %{$self->{pending}}) );
    } else {
	# Nothing to get, so nothing to return
	return;
    }

    # Get the details of all the items we are interested in.
    # Ignore any failures - ct commands will return failure if only one
    # item name is non-existent, but they'll still return the details of the
    # other items.
    my ($status,$stdout) = $self->ct(\@selectCommand,splitStdout=>0,returnFail=>1);

    foreach my $details ($self->_splitGetCommandOutput($stdout)) {
	my $h = $self->_unpack([split('\n',$details)]);
	my $name = $h->{$self->_nameField};
	delete $self->{pending}{$name};
	$self->{collection}{$name} ||= $self->{itemClass}->_get($self, $h);
	push @gotten, $self->{collection}{$name};
    }
    $self->{gotAll} = 1 unless @names;
    return @gotten;
}

#######################################
# External interface

# Get all the items - return a list of all items
sub getAll {
    my $self = shift;
    $self->_getSome();
    return values %{$self->{collection}};
}

# Get items, based on the name of the items.
# Return undef if no such item.
# If one item was asked for and we are in scalar mode, return that item;
# otherwise return a list.

sub getOne {
    my $self = shift;
    return () if !@_;   # If nothing is asked for, give it (in abundance)
    $self->_getSome(@_);
    if (defined wantarray and wantarray eq '' and @_ == 1) {
	return $self->{collection}{$_[0]};
    } else {
	return map { $self->{collection}{$_} } @_;
    }
}

# Remove an item from the collection - typically used
# when an item is deleted, e.g. rmview.
sub forget {
    my $self = shift;
    my $name = shift;
    delete $self->{collection}{$name};
}

# Add an item to the collection - typically used when
# an item is created, e.g. mkview.  Note that this
# doesn't actually add the item details since this would
# require a call to cleartool - instead it remembers that
# the named item is pending
sub add {
    my $self = shift;
    my $name = shift;
    $self->{pending}{$name} = 1;
}

###############################################################################

=head1 ClearCase::Component

Inherits from ClearCase::Thing ClearCase::TriggerMixin ClearCase::RenameMixin

=cut

package ClearCase::Component;

our @ISA = qw(ClearCase::Thing ClearCase::ProjectVobThingMixin ClearCase::TriggerMixin ClearCase::RenameMixin);

sub format { 'Name: %n\nCreated: %d\nLocked: %[locked]p\nInitial Baseline: %[initial_bl]p\nRoot: %[root_dir]p\n\n' }

#######################################
#-- ACCESSORS

=head2 name() -> string

=cut

sub name { $_[0]->{Name} }

=head2 specifier() -> string

Returns the name of the component in the form 'component:<name>@<vob>'

=cut

sub specifier {
    my $self = shift;
    return 'component:'.$self->name.'@'.$self->pvob->name;
}

=head2 created() -> string

=cut

sub created { $_[0]->{Created} }

=head2 locked() -> 'locked' | 'unlocked' | 'obsolete'

=cut 

sub locked { $_[0]->{Locked} }

=head2 initial_baseline() -> ClearCase::Baseline

=cut

sub initial_baseline {
    my $self = shift;
    return $self->pvob->baseline($self->{'Initial Baseline'});
}

=head2 root() -> path

=cut

sub root { $_[0]->{Root} }

#######################################
#-- OPERATORS

=head2 rmcomponent() -> 0 | 1

=cut
sub rmcomponent {
    my $self = shift;

    my ($status) = $self->ct(['rmcomponent','-force', $self->specifier],leaveStdout=>1,leaveStderr=>1,returnFail=>1);

    return undef if $status != 0;

    $self->{parent}->forget($self->name);

    return 1;
}

###############################################################################
package ClearCase::ComponentCollection;

our @ISA = qw(ClearCase::Collection ClearCase::ProjectVobThingMixin);

sub _getCommand {
    # Different command depending on whether we want all or some items
    my $self = shift;
    my @names = @_;

    my @wanted;

    if (@names) {
	# Want just some items
	@wanted = map { "component:$_\@".$self->vob->name } @names;
    } else {
	# Want all items
	@wanted = ('-invob',$self->vob->name);
    }

    return('lscomp','-fmt',ClearCase::Component->format,@wanted);
}

sub _nameField { 'Name' }

###############################################################################

=head1 ClearCase::ConfigRecord

Not yet implemented - sorry!

=cut

package ClearCase::ConfigRecord;


our @ISA = qw(ClearCase::Thing ClearCase::ViewThingMixin);
# TBD

#######################################
#-- CONSTRUCTOR

sub _get {
    my $class = shift;
    my $derivedObject = shift;
    # TBD
}

#######################################
#-- ACCESSORS

sub sources { }
sub directories { }
sub symlinks { }
sub derivedObjects {}
sub makefiles {}
sub viewPrivateFiles {}
sub nonMVFSobjects {}
sub host {}
sub refTime {}
sub auditStartTime {}
sub view {}
sub workingDirectory {}
sub variables {}
sub variable {}
sub buildScript {}

###############################################################################
package ClearCase::CurrentRegion;

# Internal package that overrides some of the methods of ClearCase::Region

our @ISA = qw(ClearCase::Region);


sub _lsview {
    my $self = shift;
    my ($stdout) = $self->ct(['lsview','-long'],splitStdout=>0);
    return $stdout;
}

sub _lsvob {
    my $self = shift;
    my ($stdout) = $self->ct(['lsvob','-long'],splitStdout=>0);
    return $stdout;
}


=head2 name() -> string

=cut

sub name {
    $_[0]->{parent}->currentHost->region->name;
}

###############################################################################

=head1 ClearCase::CurrentView

Inherits from ClearCase::View.

This is the class of the object returned by $cc->cwv.  It extends the ClearCase::View
class, but there are several things that you can do in the current view that you can't
do in other views, such as moving and linking elements.  

=cut

package ClearCase::CurrentView;

# Inherits everything from ClearCase::View
our @ISA = qw(ClearCase::View);

sub _get {
    my $class = shift;
    my $parent = shift;
    my ($status,$stdout) = $class->ct(['lsview','-long','-cview'],returnFail=>1);
    return undef unless $status == 0;
    $class->SUPER::_get($parent,$class->_unpack($stdout));
}

sub _lsco {
    my $self = shift;
    my ($stdout) = $self->ct(['lsco','-avobs','-cview','-fmt',$ClearCase::Checkout::format],splitStdout=>0);
    return $stdout;
}

sub _viewroot {
    return '';
}

=head2 ln(<ct ln options and args>) => 0 | 1

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub ln {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'ln',
					-slink => '',
					-comment => 's',
					);

    $cmd->prepare(@_);
    $cmd->run();

    return $cmd->retval;
}

=head2 mv(<ct mv options and args>) => 0 | 1

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mv {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'mv',
					-comment => 's',
					);
    $cmd->prepare(@_);
    $cmd->run();

    return $cmd->retval;
}
    
=head2 rm(<ct rm options and args>) => 0 | 1

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub rm {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'rm',
					-comment => 's',
					);
    $cmd->prepare(@_);
    $cmd->run();

    return $cmd->retval;
}

=head2 mkdir(<ct mkdir options and args>) => 0 | 1

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut
  
sub mkdir {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'mkdir',
					-comment => 's',
					-nco => '',
					-master => '',
					);

    $cmd->prepare(@_);
    $cmd->run();

    return $cmd->retval unless $cmd->status;
    return $cmd->retval($self->lscheckout($self->path)) if defined wantarray;
}

=head2 mkelem(<ct mkelem options and args>) => 0 | 1

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mkelem {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'mkelem',
					-comment => 's',
					-eltype => 's',
					-nco => '',
					-ci => '',
					-ptime => '',
					-master => '',
					-mkpath => '',
					);

    $cmd->prepare(@_);
    $cmd->run();

    return $cmd->retval unless $cmd->status;

    return $cmd->retval($self->lscheckout($self->path)) if defined wantarray;
}

=head2 checkin(<ct checkin options and args>) => 0 | 1

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub checkin {
    # Check in a list of files
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'checkin',
					-comment => 's',
					-keep => '',
					-rm => '',
					-identical => '',
					-activity => 's',
					);

    $cmd->prepare(@_);

    my @checkouts = $cmd->args;

    $cmd->run();

    if ($cmd->status) {
	delete $self->{view}{checkout}{@checkouts};
    } else {
	# If the command failed, forget all we know about checkouts
	# since it is hard to tell what succeeded and what didn't
	delete $self->{view}{checkout}
    }
    
    return $cmd->retval;
}

###############################################################################
package ClearCase::DerivedObject;

=head1 ClearCase::DerivedObject

Not yet implemented

=cut

our @ISA = qw(ClearCase::Thing ClearCase::ViewThingMixin);

#######################################
#-- CONSTRUCTOR

#######################################
#-- OPERATORS

sub rmdo {
    my $self = shift;
    # TBD 
}

###############################################################################
package ClearCase::DirectoryElement;

=head1 ClearCase::DirectoryElement

Represents a directory element.  Not fully implemented.  Extends ClearCase::Element.

=cut

our @ISA = qw(ClearCase::Element ClearCase::Thing ClearCase::VobThingMixin);

###############################################################################
package ClearCase::DirectoryVersion;

=head1 ClearCase::DirectoryVersion

Represents a directory version.  Not fully implemented.  Extends ClearCase::Version.

=cut

our @ISA = qw(ClearCase::Version ClearCase::Thing ClearCase::VobThingMixin);

###############################################################################
package ClearCase::Element;

=head1 ClearCase::Element

Represents an element.  Not fully implemented.

=cut

our @ISA = qw(ClearCase::Thing ClearCase::VobThingMixin);

#######################################
#-- CONSTRUCTOR

sub _get {
    my $class = shift;
    my $oid = shift;
    return bless {oid => $oid}, $class;
}

#######################################
package ClearCase::FlatConfigRecord;

# Internal class to extend config records

our @ISA = qw(ClearCase::ConfigRecord);

#######################################
#-- CONSTRUCTOR

#######################################
#-- ACCESSORS

sub fileCount { } # Returns number of times file was used

###############################################################################

=head1 ClearCase::Folder

=cut

package ClearCase::Folder;


our @ISA = qw(ClearCase::Thing ClearCase::ProjectVobThingMixin ClearCase::TriggerMixin ClearCase::RenameMixin);


sub format { 'Name: %n\nOwner: %[owner]p\nLocked: %[locked]p\n\n' }

#######################################
#-- ACCESSORS


=head2 name() -> string

=cut

sub name { return $_[0]->{Name} }

=head2 owner() -> string

=cut

sub owner { return $_[0]->{Owner} }

=head2 locked() -> 'locked' | 'unlocked' | 'obsolete'

=cut 

sub locked { return $_[0]->{Locked} }


=head2 specifier() -> string

Returns the name of the folder in the form 'folder:<name>@<vob>'

=cut

sub specifier {
    my $self = shift;
    return 'folder:'.$self->name.'@'.$self->pvob->name;
}

=head2 folders() -> ( ClearCase::Folder,... )

=cut

# Return list of folders in this folder - do not cache anything
# since maintaining the list is not trivial, though this could be
# added. TBD
sub folders {
    my $self = shift;
    my ($stdout) = $self->ct(['lsfolder','-short','-in',$self->specifier]);
    return $self->pvob->folder(@$stdout);
}

=head2 folder(name,...) -> ClearCase::Folder,...

Returns the named folder.  You might expect this to fail if this folder
doesn\'t have a subfolder with the right name, but in order to make things
run faster, this simply returns any folder in this pvob with the right name.
If you want to check that the subfolder is in this folder, use folders().

=cut 

# Don't bother checking - if a named folder is wanted, just pass
# the request up to the pvob.  Maybe it should fail if the folder is not
# a subfolder of this one, but that's for the future TBD.
sub folder {
    my $self = shift;
    return $self->pvob->folder(@_);
}

=head2 projects() -> ( ClearCase::Projects,... )

=cut
    
# Return list of projects in this folder - do not cache anything
# since maintaining the list is not trivial, though this could be
# added. TBD
sub projects {
    my $self = shift;
    my ($stdout) = $self->ct(['lsproject','-short','-in',$self->specifier]);
    return $self->pvob->project(@$stdout);
}

=head2 project(name,...) -> ClearCase::Project,...

Returns the named project.  You might expect this to fail if this folder
doesn\'t have a subproject with the right name, but in order to make things
run faster, this simply returns any project in this pvob with the right name.
If you want to check that the subproject is in this folder, use projects().

=cut 

# Don't bother checking - if a named project is wanted, just pass
# the request up to the pvob.  Maybe it should fail if the project is not
# a subproject of this one, but that's for the future TBD.
sub project {
    my $self = shift;
    return $self->pvob->project(@_);
}
    
#######################################
#-- OPERATORS

=head2 mkproject(<ct mkproject options>) -> ClearCase::Project

Don\'t specify the -in - this is set automatically.  Support for
-modcomp is TBD

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mkproject {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'mkproject',
					-comment => 's',
#					-modcomp => undef,   # array of ClearCase::Component TBD
					-policy => 's',
					-npolicy => 's',
					-spolicy => 's',
					-model => 's', # 'DEFAULT' or 'SIMPLE'
					-crmenable => 's',
					-blname_template => 's',
					);

    $cmd->prepare(@_);
    $cmd->setOpt('-in'=>$self->specifier);
    $cmd->run();

    return $cmd->retval unless $cmd->status;

    my ($projectName) = $cmd->args;

    $self->pvob->{projects}->add($projectName);

    return $cmd->retval($self->pvob->project($projectName)) if defined wantarray;
}

=head2 mkfolder(<ct mkfolder options>) -> ClearCase::Folder

Don\'t specify the -in - this is set automatically.

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mkfolder {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'mkfolder',
					-comment => 's',
					);

    $cmd->prepare(@_);
    $cmd->setOpt('-in'=>$self->specifier);
    $cmd->run();

    return $cmd->retval unless $cmd->status;

    my ($folderName) = $cmd->args;

    $self->pvob->add($folderName);

    return $cmd->retval($self->pvob->folder($folderName)) if defined wantarray;
}

# These two are TBD
#sub setComment {
#    # TBD
#}
# Not sure how to move a folder...
#sub move {
#    my $self = shift;
#    my $to = shift; # Target ClearCase::Folder to move to
#    my ($status,$stdout) = 
#      $self->_run('move',
#		      {
#			  -comment => undef,
#		      },
#		      \@_,
#		      [ $to ],
#		      leaveStderr=>1,
#		      returnFail=>1,
#		      );
#
#    # TBD
#}

=head2 rmfolder() -> 0 | 1

=cut

sub rmfolder {
    my $self = shift;


    my ($status) = 
	$self->ct(['rmfolder','-nc','-force',$self->specifier],leaveStdout=>1,leaveStderr=>1,returnFail=>1);
    return undef if $status != 0;

    $self->{parent}->forget($self->name);

    return 1;
}

###############################################################################
package ClearCase::FolderCollection;

our @ISA = qw(ClearCase::Collection ClearCase::ProjectVobThingMixin);

sub _getCommand {
        # Different command depending on whether we want all or some items
    my $self = shift;
    my @names = @_;

    my @wanted;

    if (@names) {
	# Want just some items
	@wanted = map { "folder:$_\@".$self->vob->name } @names;
    } else {
	# Want all items
	@wanted = ('-invob',$self->vob->name);
    }

    return('lsfolder','-fmt',ClearCase::Folder->format,@wanted);
}

sub _nameField { 'Name' }

###############################################################################

=head1 ClearCase::Hlink

This class is not properly implemented yet - it will be when the full vtree support
is added, including branches and elements.

=cut

package ClearCase::Hlink;

our @ISA = qw(ClearCase::Thing ClearCase::VobThingMixin ClearCase::RenameMixin ClearCase::ProtectMixin);

#######################################
#-- CONSTRUCTOR

#######################################
#-- OPERATORS

sub rmhlink {
    my $self = shift;
    my ($status,$stdout) = 
      $self->_run('rmhlink',
		      {
			  -comment => undef,
		      },
		      \@_,
		      [ 'TBD' ],
		      leaveStderr=>1,
		      returnFail=>1,
		      );
    # TBD
}

###############################################################################

=head1 ClearCase::HlType

Inherits from ClearCase::Thing, ClearCase::RenameMixin, ClearCase::ProtectMixin,
ClearCase::LockMixin, ClearCase::Type, ClearCase::AttributeMixin.

Merge arrows are just instances of a predefined hltype, so if you want to do
things with merge arrows you should get the type hlType('merge') first.

=cut

package ClearCase::HlType;

our @ISA = qw(ClearCase::Thing ClearCase::VobThingMixin ClearCase::RenameMixin ClearCase::ProtectMixin ClearCase::LockMixin ClearCase::Type ClearCase::AttributeMixin);

sub format { 'Name: %n\nCreated: %d\nLocked: %[locked]p\nScope: %[type_scope]p\nOwner: %u\n\n' }
sub kind { 'hltype' }

#######################################
#-- ACCESSORS

=head2 name() -> string

=cut

sub name { return $_[0]->{Name} }

=head2 created() -> string

=cut

sub created { return $_[0]->{Created} }

=head2 locked() -> 'locked' | 'unlocked' | 'obsolete'

=cut 

sub locked { return $_[0]->{Locked} }

=head2 scope() -> 'ordinary' | 'global' | 'local copy'

=cut 

sub scope { return $_[0]->{Scope} }

#######################################
#-- OPERATORS

=head2 mkhlink(<ct mkhlink options & args>) -> 0 | 1

Do not specify the hltype.  This does not return a ClearCase::HlType, but
it may be changed in the future to do this.

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mkhlink {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'mkhlink',
					-unidir => 0,
					-text => undef,
					-ftext => undef,
					-fpname => 0,
					-tpname => 0,
					-acquire => 0,
					-comment => undef,
					);
    $cmd->prepare(@_);
    $cmd->setArgs($self->specifier, $cmd->args);
    $cmd->run();

    return $cmd->retval;
}

###############################################################################
package ClearCase::HlTypeCollection;

our @ISA = qw(ClearCase::TypeCollection);

###############################################################################

=head1 ClearCase::Host

Represents a host as seen by ClearCase.

=cut

package ClearCase::Host;

our @ISA = qw(ClearCase::Thing);

#######################################
#-- ACCESSORS


=head2 name() -> string

=cut

sub name { return $_[0]->{Client} }

=head2 product() -> string

=cut

sub product { return $_[0]->{Product} }

=head2 operatingSystem() -> string

=cut

sub operatingSystem { return $_[0]->{'Operating system'} }

=head2 hardwareType() -> string

=cut

sub hardwareType { return $_[0]->{'Hardware type'} }

=head2 registryHost() -> string

=cut

sub registryHost { return $_[0]->{'Registry host'} }

=head2 licenseHost() -> string

=cut

sub licenseHost { return $_[0]->{'License host'} }


=head2 region() -> ClearCase::Region

=cut

sub region {
    my $self = shift;
    # Parent of host is HostCollection;it's parent is the ClearCase object
    return $self->{parent}->{parent}->region($self->{'Registry region'});
}

###############################################################################
package ClearCase::HostCollection;

use Memoize;
our @ISA = qw(ClearCase::Collection);

# HostCollection is a different type of collection - there is no 
# way to get details of all hosts, just named hosts or by default
# the current host.

sub _getCommand { shift; 'hostinfo','-long',@_ }
sub _nameField { 'Client' }

# Special method to get current host - call _getSome with no arguments
# and it'll return a list of one ClearCase::Host, which will be this host.
memoize('getCurrent');
sub getCurrent {
    my $self = shift;
    # Make sure there is nothing in the collection, which will force it to
    # call hostinfo
    $_->{gotAll} = 0;
    $_->{collection} = {};
    return ($self->_getSome())[0];
}
    
###############################################################################

=head1 ClearCase::Label

Represents a single label on an item.  Use ClearCase::LbType->mklabel to create
a label.

=cut

package ClearCase::Label;

our @ISA = qw(ClearCase::Thing ClearCase::VobThingMixin);

sub _get {
    my $class = shift;
    my $version = shift;
    my $lbtype = shift;
    bless {
	version => $version,
	lbtype => $lbtype,
    }, $class;
}

=head2 rmlabel(<ct rmlabel options and args>) -> 0 | 1

Do not specify the label name or type, or the version.

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub rmlabel {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'rmlabel',
					-comment => 's',
					-recurse => '',
					-follow => '',
					);

    $cmd->prepare(@_);
    $cmd->setArgs($self->lbtype->specifier,$self->version->name);
    $cmd->run();

    return $cmd->retval;
}

###############################################################################

=head1 ClearCase::LbType

Inherits from ClearCase::Thing, ClearCase::RenameMixin, ClearCase::ProtectMixin, ClearCase::LockMixin, ClearCase::Type, ClearCase::AttributeMixin
=cut

package ClearCase::LbType;

our @ISA = qw(ClearCase::Thing ClearCase::VobThingMixin ClearCase::RenameMixin ClearCase::ProtectMixin ClearCase::LockMixin ClearCase::Type ClearCase::AttributeMixin);

sub format { 'Name: %n\nCreated: %d\nLocked: %[locked]p\nScope: %[type_scope]p\nConstraint: %[type_constraint]p\nMaster replica: %[master]p\nType mastership: %[type_mastership]p\nOwner: %u\n\n' }

sub kind { 'lbtype' }

#######################################
#-- ACCESSORS


=head2 name() -> string

=cut

sub name { return $_[0]->{Name} }

=head2 created() -> string

=cut

sub created { return $_[0]->{Created} }

=head2 locked() -> 'locked' | 'unlocked' | 'obsolete'

=cut 

sub locked { return $_[0]->{Locked} }

=head2 scope() -> 'ordinary' | 'global' | 'local copy'

=cut 

sub scope { return $_[0]->{Scope} }

=head2 constraint() -> 'one version per element' | 'one version per branch'

=cut 

sub constraint { return $_[0]->{Constraint} }

=head2 masterReplica() -> string

=cut

sub masterReplica { return $_[0]->{'Master replica'} }

=head2 typeMastership() -> 'shared' | 'unshared'

=cut

sub typeMastership { return $_[0]->{'Type mastership'} }

=head2 owner() -> string

=cut

sub owner { return $_[0]->{Owner} }

###############################################################################
package ClearCase::LbTypeCollection;

our @ISA = qw(ClearCase::TypeCollection);

###############################################################################
package ClearCase::Lock;

=head1 ClearCase::Lock

Represents a lock on a clearcase object.

=cut

our @ISA = qw(ClearCase::Thing ClearCase::VobThingMixin);

sub _get {
    my $class = shift;
    my $parent = shift;
    my $details = shift;

    # Need to parse the output carefully...
    my $status;
    if ($details =~ /\(obsolete\)/) {
	$status = 'obsolete';
    } else {
	$status = 'locked';
    }

    my @nusers;

    if ($details =~ /\"Locked except for users: (.*)\"/) {
	@nusers = split(' ',$1);
    }

    bless {
	status => $status,
	parent => $parent,
	nusers => \@nusers,
    }, $class;
}

=head2 status() -> 'locked' | 'obsolete'

=cut

sub status { return $_[0]->{status} }

sub nusers { return @{$_[0]->{nusers}} }

###############################################################################

=head1 ClearCase::LockMixin

Provides lock-related methods for all objects that can be locked, e.g. vobs, elements,
label types, etc.

=cut

package ClearCase::LockMixin;

=head1 lslock() -> ClearCase::Lock | undef

Returns a ClearCase::Lock object if the object is locked, undef otherwise.

=cut

sub lslock {
    my $self = shift;
    my ($stdout) = $self->ct(['lslock',$self->specifier],leaveStdout=>0,leaveStderr=>1);
    return unless @$stdout;   # no output = no lock
    _get ClearCase::Lock $self, $stdout->[1];  # Pass the second line of lslock output to the constructor
}

=head1 lock(<ct lock options>) -> ClearCase::Lock

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub lock {
    my $self = shift;
    my $cmd = new ClearCase::Cleartool (
					'lock',
					-comment => 's',
					-replace => '',
					-nusers => 's',
					-obsolete => '',
					-version => '',
					);
    $cmd->prepare(@_);
    $cmd->setArgs($self->specifier);
    $cmd->run();

    return $cmd->retval unless $cmd->status;

    return $cmd->retval($self->lslock()) if defined wantarray;
}

=head1 unlock([-comment=>"comment"]) -> 0 | 1

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub unlock {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'unlock',
					-comment => 's',
					);
    $cmd->prepare(@_);
    $cmd->setArgs(self->specifier);
    $cmd->run();

    return $cmd->retval;
}	    

###############################################################################

=head1 ClearCase::Path

Represents a filesystem path, possible a version-path extended path.

=cut

package ClearCase::Path;

our @ISA = qw(ClearCase::Thing);

sub _get {
    my $class = shift;
    my $path = shift;
    return bless { path => $path }, $class;
}

#######################################
#-- ACCESSORS

=head2 name() -> path

=cut

sub name { return $_[0]->{path} }

=head2 path() -> path

=cut

sub path { return $_[0]->{path} }

=head2 isVisible() -> true | false

Returns true if this path should be visible in the current view; i.e. if
there are no directory versions in the path.

=cut

sub isVisible {
    my $self = shift;
    # Turns out to be very simple - if there are number entries in the version-extended
    # part of the pathname, e.g. .../23/..., then that must be the version of
    # a directory, and therefore this path should not be visible in the current view.
    return ! $self->{path} =~ m%/\@\@/.*/\d+/%;
}

=head2 object() -> ClearCase::Version | ClearCase::Branch | ClearCase::Element | undef

Returns one of a version, branch or element depending on what the path refers to.
If the path refers to anything else, or is invalid, returns undef.

=cut 

sub object {
    my $self = shift;
    my $path = $self->{path};
    my ($stdout) = $self->ct(['describe',-fmt=>"type: %m\noid: %On\nversion: %Sn\npredecessor version: %PSn\n",$path],returnFail=>0,leaveStdout=>0,leaveStderr=>1);

    my $f = $self->_unpack($stdout);

    my $retval;

    if ($f->{type} eq 'directory element') {
	$retval = _get ClearCase::DirectoryElement $self->{path},$f->{oid};
    } elsif ($f->{type} eq 'element') {
	$retval = _get ClearCase::Element $self->{path},$f->{oid};
    } elsif ($f->{type} eq 'branch') {
	$retval = _get ClearCase::Branch $self->{path},$f->{oid}, $f->{version};
    } elsif ($f->{type} eq 'directory version') {
	$retval = _get ClearCase::DirectoryVersion $self->{path},$f->{oid},$f->{version},$f->{'predecessor version'};
    } elsif ($f->{type} eq 'version') {
	$retval = _get ClearCase::Version $self->{path},$f->{oid},$f->{version},$f->{'predecessor version'};
    }

    return $retval;
}

###############################################################################

=head1 ClearCase::Project

Inherits from ClearCase::Thing, ClearCase::TriggerMixin, ClearCase::RenameMixin, ClearCase::AttributeMixin, ClearCase::LockMixin

=cut

package ClearCase::Project;

our @ISA = qw(ClearCase::Thing ClearCase::ProjectVobThingMixin ClearCase::TriggerMixin ClearCase::RenameMixin ClearCase::AttributeMixin ClearCase::LockMixin);


sub format { 'Name: %n\nOwner: %[owner]p\nLocked: %[locked]p\nIntegration Stream: %[istream]p\n\n' }
sub extraLsFlags { '-obsolete' }

#######################################
#-- ACCESSORS

=head2 name() -> string

=cut

sub name { return $_[0]->{Name} }

=head2 owner() -> string

=cut

sub owner { return $_[0]->{Owner} }

=head2 istream() -> ClearCase::Stream

The integration stream for the project

=cut

sub istream {
    my $self = shift;
    return $self->pvob->stream($self->{'Integration Stream'});
}

=head2 specifier() -> string

Returns the name of the project in the form 'project:<name>@<vob>'

=cut

sub specifier {
    my $self = shift;
    return 'project:'.$self->name.'@'.$self->pvob->name;
}

=head2 streams() -> ( ClearCase::Stream,... )

=cut 

sub streams {
    my $self = shift;
    my ($stdout) = $self->ct(['lsstream','-short','-in',$self->specifier],leaveStdout=>0,returnFail=>0);
    return $self->pvob->stream(@$stdout);
}

=head2 stream(streamname,...) -> ClearCase::Stream,...

=cut 

sub stream {
    my $self = shift;
    my $streamName = shift;
    return $self->pvob->stream($streamName);
}

#######################################
#-- OPERATORS

=head2 rmproject() -> 0 | 1

=cut

sub rmproject {
    my $self = shift;

    my ($status) = 
	$self->ct(['rmproject','-nc','-force',$self->specifier],leaveStdout=>1,leaveStderr=>1,returnFail=>1);
    return undef if $status != 0;

    $self->{parent}->forget($self->name);

    return 1;
}

=head2 mkstream(<ct mkstream options & args>) -> ClearCase::Stream

-baseline support is TBD

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mkstream {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'mkstream',
					-integration => '',
					-comment => 's',
# TBD					-baseline => [], # List of ClearCase::Baseline
					-policy => 's',
					-npolicy => 's',
					-target => 'ClearCase::Stream',
					-readonly => '',
					);
    $cmd->prepare(@_);
    $cmd->setOpt(-in=>$self->specifier);
    $cmd->run();

    return $cmd->retval unless $cmd->status;

    my ($streamName) = $cmd->args;
    
    $self->pvob->{streams}->add($streamName);

    return $cmd->retval($self->pvob->stream($streamName)) if defined wantarray;
}

###############################################################################
package ClearCase::ProjectCollection;

our @ISA = qw(ClearCase::Collection ClearCase::ProjectVobThingMixin);


# Unfortunately a bug in version 7.2 of ClearCase means that we need to 
# get the list of projects by iterating over the folders - lsproject will
# not give us the full list the simple way, it'll omit projects that are lower
# down in the folder hierarchy.

sub _getCommand { 
    # This command is only used if we want a list
    my $self = shift;
    my @names = @_;
    my @wanted = map { "project:$_\@".$self->pvob->name } @names;
    return ('lsproject','-fmt',ClearCase::Project->format,ClearCase::Project->extraLsFlags,@wanted);
}

sub _nameField { 'Name' }

sub _getSome {
    my $self = shift;
    my @names = @_;

    my @selectCommand;
    my @gotten; # List of things that were requested

    if (@names) {
	# Only need to get things that are not already in the hash.
	# extract the short name from the middle of a specifier
	my @needed = grep { /^(.*?\:)?(.*?)(\@.*)?$/; !$_ || !exists $self->{collection}{$2} } @names;
	return unless @needed;
	@selectCommand = ( $self->_getCommand(@needed) );

    } elsif (!$self->{gotAll}) {
	# Haven't got everything yet but we want everything, so get it
	# Leave @selectCommand blank since this is the special case

    } elsif (%{$self->{pending}}) {
	# There are pending items that haven't been got yet, so get them
	@selectCommand = ( $self->_getCommand(keys %{$self->{pending}}) );
    } else {
	# Nothing to get, so nothing to return
	return;
    }

    # Get the details of all the items we are interested in.
    # Ignore any failures - ct commands will return failure if only one
    # item name is non-existent, but they'll still return the details of the
    # other items.
    my ($status,$stdout);
    if (@selectCommand) {
	($status,$stdout) = $self->ct(\@selectCommand,splitStdout=>0,returnFail=>1);
    } else {
	# Want all projects, so iterate through all folders
	foreach my $folder ($self->pvob->folders) {
	    my ($lstatus,$lstdout) = $self->ct(['lsproject','-fmt',ClearCase::Project->format,ClearCase::Project->extraLsFlags,'-in',$folder->specifier],splitStdout=>0,returnFail=>1);
	    $stdout .= $lstdout;
	}
    }

    foreach ($self->_splitGetCommandOutput($stdout)) {
	my $h = $self->_unpack([split('\n',$_)]);
	my $name = $h->{$self->_nameField};
	delete $self->{pending}{$name};
	$self->{collection}{$name} ||= $self->{itemClass}->_get($self, $h);
	push @gotten, $self->{collection}{$name};
    }
    $self->{gotAll} = 1;
    return @gotten;
}


###############################################################################

=head1 ClearCase::ProjectVob

Inherits from ClearCase::Vob

=cut

package ClearCase::ProjectVob;

# A pvob is a vob with a few extra methods

our @ISA = qw(ClearCase::Vob);

sub _get {
    my $class = shift;
    my $parent = shift;
    my $fields = shift;
    # Special constructor - first get the vob object
    my $self = $parent->parent->vob($fields->{Tag});
    bless $self, $class;  # Change the type of the object to a pvob
    $self->{components} = new ClearCase::ComponentCollection $self;
    $self->{folders} = new ClearCase::FolderCollection $self;
    $self->{projects} = new ClearCase::ProjectCollection $self;
    $self->{streams} = new ClearCase::StreamCollection $self;
    $self->{activities} = new ClearCase::ActivityCollection $self;
    $self->{baselines} = new ClearCase::BaselineCollection $self;
    return $self;
}
    
#######################################
#-- ACCESSORS

# The pvob is structured so that folders, projects, streams,
# etc. are all owned by their respective container; a pvob
# only contains the root folder and everything else is derived
# from that.

sub pvob { $_[0] }
sub vob { $_[0] }

=head2 components() -> ( ClearCase::Component,... )

=cut

sub components { $_[0]->{components}->getAll }

=head2 component(componentName,...) -> ClearCase::Component,...

=cut

sub component { my $self = shift; $self->{components}->getOne(@_) }

=head2 folders() -> ( ClearCase::Folder,... )

=cut

sub folders { $_[0]->{folders}->getAll }

=head2 folder(folderName,...) -> ClearCase::Folder,...

=cut

sub folder  { my $self = shift; $self->{folders}->getOne(@_) }

=head2 rootFolder() -> ClearCase::Folder

The root folder in a project vob is always called RootFolder,so
this is the same as folder('RootFolder').

=cut

sub rootFolder { my $self = shift; $self->{folders}->getOne('RootFolder') }

=head2 projects() -> ( ClearCase::Project,... )

=cut

sub projects { $_[0]->{projects}->getAll }

=head2 project(projectName,...) -> ClearCase::Project,...

=cut

sub project { my $self = shift; $self->{projects}->getOne(@_); }

=head2 streams() -> ( ClearCase::Stream,... )

=cut

sub streams { $_[0]->{streams}->getAll }

=head2 stream(streamName,...) -> ClearCase::Stream,...

=cut

sub stream { my $self = shift; $self->{streams}->getOne(@_) }

=head2 activities() -> ( ClearCase::Activity,... )

=cut

sub activities { $_[0]->{activities}->getAll }

=head2 activity(activityName,...) -> ClearCase::Activity,...

=cut

sub activity { my $self = shift; $self->{activities}->getOne(@_) }

=head2 baselines() -> ( ClearCase::Baseline,... )

=cut

sub baselines { $_[0]->{baselines}->getAll }

=head2 baseline(baselineName,...) -> ClearCase::Baseline,...

=cut

sub baseline { my $self = shift; $self->{baselines}->getOne(@_) }

#######################################
#-- OPERATORS

=head2 mkcomp(<ct mkcomp options & args>) -> ClearCase::Component

Do not specify the pvob, i.e. just give the component name.

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mkcomp {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'mkcomp',
					-comment => 's',
					-root => 's',
					-nroot => '',
					);
    $cmd->prepare(@_);
    $cmd->run();

    return $cmd->retval unless $cmd->status;

    my ($componentName) = $cmd->args;

    $self->{components}->add($componentName);

    return $cmd->retval($self->component($componentName)) if defined wantarray;
}

###############################################################################
package ClearCase::ProjectVobCollection;

our @ISA = qw(ClearCase::Collection);

sub _getCommand { 'lsvob' }

sub _splitGetCommandOutput {
    # Just return entries that are for pvobs
    my $self = shift;
    my $output = shift;
    my @retval;
    foreach (split /^/, $output) {
	/(\*| )\s+(.*?)\s+(.*?)\s+(private|public)\s*(\((.*)\))?/;
	my ($active,$tag,$path,$private,$flags) = ($1,$2,$3,$4,$6);
	next unless $flags;   # No flags means definitely not a pvob
	my %flags = map { $_ => 1 } split(',',$flags);
	if ($flags{ucmvob}) {
	    push @retval, "Tag: $tag\n";
	}
    }
    return @retval;
}

sub _nameField { "Tag" }

###############################################################################
package ClearCase::ProjectVobThingMixin;

our @ISA = qw(ClearCase::VobThingMixin);

# Mixin for things in a pvob, i.e. things with a pvob somewhere in their parentage
# Compare with ClearCase::ViewThingMixin and ClearCase::VobThingMixin
sub pvob { $_[0]->{parent}->pvob }

###############################################################################

=head1 ClearCase::ProtectMixin

Provides the protect method to all clearcase objects that support protection.

=cut

package ClearCase::ProtectMixin;

=head2 protect(<ct protect options>) -> 0 | 1

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub protect {
    my $self = shift;
    my $cmd = new ClearCase::Cleartool (
					'protect',
					-chown => 's',
					-chgrp => 's',
					-chmod => 's',
					-comment => 's',
					-recurse => '',
					-file => '',
					-directory => '',
					);
    $cmd->prepare(@_);
    $cmd->setArgs($self->specifier);
    $cmd->run();

    return $cmd->retval;
}

###############################################################################
package ClearCase::RecurseConfigRecord;

# Internal class to extend config records

our @ISA = qw(ClearCase::ConfigRecord);

#######################################
#-- CONSTRUCTOR

###############################################################################

=head1 ClearCase::Region

Inherits from ClearCase::Thing

=cut

package ClearCase::Region;

our @ISA = qw(ClearCase::Thing);

#######################################
#-- CONSTRUCTOR

sub _get {
    my $class = shift;
    my $parent = shift;
    my $fields = shift;
    my $self = $class->SUPER::_get($parent,$fields);
    $self->{vobs} = new ClearCase::VobCollection $self;
    $self->{projectvobs} = new ClearCase::ProjectVobCollection $self;
    $self->{views} = new ClearCase::ViewCollection $self;
    return $self;
}

#######################################
#-- ACCESSORS


=head2 name() -> string

=cut

sub name { return $_[0]->{Tag} }

=head2 views() -> ( ClearCase::View,... )

=cut

sub views { $_[0]->{views}->getAll }

=head2 view(name,...) -> ClearCase::View,...

=cut

sub view  { my $self = shift; $self->{views}->getOne(@_) }

=head2 vobs() -> ( ClearCase::Vob,... )

=cut

sub vobs { $_[0]->{vobs}->getAll }

=head2 vob(name,...) -> ClearCase::Vob,...

=cut

sub vob  { my $self = shift; $self->{vobs}->getOne(@_) }

=head2 pvobs() -> ( ClearCase::ProjectVob,... )

=cut

sub pvobs { $_[0]->{projectvobs}->getAll }

=head2 pvob(name,...) -> ClearCase::ProjectVob,...

=cut

sub pvob  { my $self = shift; $self->{projectvobs}->getOne(@_) }

sub _rmVob {
    $_[0]->{vobs}->forget($_[1]);
    $_[0]->{projectvobs}->forget($_[1]);
}

#######################################
#-- OPERATORS

=head2 mkviewtag(<mktag options & arguments>) -> 1 | undef

No need to specify region.  Does not support -replace - this is TBD.
Does not return a view or vob object - if you want to acc

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mktag {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'mktag',
					-view => '',
					-tag => 's',
					-tcomment => 's',
					-nstart => '',
					-ncaexported => '',
					-host => 'ClearCase::Host',
					-gpath => 's',
					-vob => '',
					-options => 's',
					-public => '',
					-password => 's',
					);
    $cmd->prepare(@_);
    $cmd->setOpt(-region=>$self->name);
    $cmd->run();

    return $cmd->retval unless $cmd->status;

    my ($name) = $cmd->args;

    # Add an entry to the appropriate collection.
    # The resulting view or vob object may not behave
    # as expected if this isn't the current region, so
    # don't return it.
    if ($cmd->opt('-vob')) {
	$self->{vobs}->add($name);
    } else {
	$self->{views}->add($name);
    }

    return $cmd->retval;
}

=head2 rmtag(<ct rmtag options & arguments>) -> 0 | 1

Do not specify -region.  -all is not supported with this method - it
should be supported by a ClearCase method, but this is TBD.

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub rmtag {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'rmtag',
					-view => '',
					-vob => '',
					-password => 's',
					);
    $cmd->prepare(@_);
    $cmd->setOpt(-region=>$self->specifier);
    $cmd->run();

    return $cmd->retval unless $cmd->status;

    my ($name) = $cmd->args;

    if ($cmd->opt('-vob')) {
	$self->{vobs}->forget($name);
    } else {
	$self->{views}->forget($name);
    }

    return $cmd->retval;
}

=head2 mkvob(<ct mkvob opts & args>) -> ClearCase::Vob | ClearCase::ProjectVob

Returns a project vob object if -ucmproject is specified

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mkvob {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'mkvob',
					-comment => 's',
					-tcomment => 's',
					-region => 's',
					-options => 's',
					-ncaexported => '',
					-public => '',
					-password => 's',
					-nremote_admin => '',
					-host => 'ClearCase::Host',
					-hpath => 's',
					-gpath => 's',
					-stgloc => 's',  # can be -auto
					-ucmproject => '',
					);

    $cmd->prepare(@_);
    $cmd->setOpt('-region'=>$self->specifier);
    $cmd->run();

    return $cmd->retval unless $cmd->status;

    my ($name) = $cmd->args;

    $self->{vobs}->add($name);

    if ($cmd->getOpt('-ucmproject')) {
	$self->{pvobs}->add($name);
	return $cmd->retval($self->pvob($name)) if defined wantarray;
    } else {
	return $cmd->retval($self->vob($name)) if defined wantarray;
    }
}

###############################################################################
package ClearCase::RegionCollection;

our @ISA = qw(ClearCase::Collection);

sub _getCommand { 'lsregion' }
sub _nameField { 'Tag' }

sub _splitGetCommandOutput {
    my $self = shift;
    my $stdout = shift;
    return split /^/m, $stdout;
    
}

sub _unpack {
    my $self = shift;
    my $tag = shift;
    return { Tag => $tag->[0] };
}

###############################################################################

=head1 ClearCase::RenameMixin

Provides the rename() method, which is inherited by all objects that can support it.

=cut

package ClearCase::RenameMixin;

=head2 rename(<ct rename options and arguments>) -> 0 | 1

Rename this object.  Do not specify the old name.  This may invalidate
some caches and other data structures, since many of them use object names
as the key, so if you use this you may want to create a new top-level ClearCase
object and discard the old one.

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub rename {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'rename',
					-comment => 's',
					-acquire => '',
					);

    $cmd->prepare(@_);
    my ($newName) = $cmd->args;
    my $oldName = $self->name;
    $cmd->setArgs($self->specifier,$newName);
    $cmd->run();

    return $cmd->retval unless $cmd->status;

    # Now try to clean things up...

    # Change my name
    if (exists $self->{Name}) {
	$self->{Name} = $newName;
    } elsif (exists $self->{Tag}) {
	$self->{Tag} = $newName;
    }

    # Assume this object is in a collection, and update the collection
    $self->parent->forget($oldName);
    $self->parent->add($newName);

    return $cmd->retval;
}

###############################################################################

=head1 ClearCase::ReqmasterMixin;

Provides the reqmaster method to all objects that need it.

=cut

package ClearCase::ReqmasterMixin;

=head2 reqmaster(<ct reqmaster options and arguments>) -> 0 | 1

Do not specify the object being reqmastered.

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub reqmaster {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'reqmaster'
					-comment => 's',
					);
    $cmd->prepare(@_);
    $cmd->setArgs($self->specifier);
    $cmd->run();

    return $cmd->retval;
}

###############################################################################

=head1 ClearCase::Stream;

Inherits from ClearCase::Thing, ClearCase::TriggerMixin, ClearCase::RenameMixin.

=cut
package ClearCase::Stream;

use Memoize qw(memoize);

our @ISA = qw(ClearCase::Thing ClearCase::ProjectVobThingMixin ClearCase::TriggerMixin ClearCase::RenameMixin ClearCase::LockMixin);

sub format { 'Name: %n\nOwner: %[owner]p\nLocked: %[locked]p\nProject: %[project]p\n\n' }

#######################################
#-- ACCESSORS

=head2 name() -> string

=cut

sub name { return $_[0]->{Name} }

=head2 owner() -> string

=cut

sub owner { return $_[0]->{Owner} }

=head2 project() -> ClearCase::Project

=cut

sub project { my $self = shift; return $self->pvob->project($self->{Project}) }

=head2 specifier() -> string

Returns the name of the stream in the form 'stream:<name>@<vob>'

=cut

sub specifier {
    my $self = shift;
    return 'stream:'.$self->name.'@'.$self->pvob->name;
}

=head2 activities() -> ( ClearCase::Activity,... )

This may take some time, depending on the number of activities.

=cut

# Return list of activities on this stream - do not cache anything
# since maintaining the list is not trivial.
sub activities {
    my $self = shift;
    my ($stdout) = $self->ct(['lsactivity','-short','-in',$self->specifier]);
    return $self->pvob->activity(@$stdout);
}

=head2 hasActivities -> 1 | 0

Returns 1 or True if the stream has activities.  Much faster than
checking the list returned by activities().

=cut

sub hasActivities {
    my $self = shift;
    my ($stdout) = $self->ct(['lsactivity','-short','-in',$self->specifier]);
    if (@$stdout) { return 1 } else { return 0 }
}

=head2 hasViews -> 1 | 0

Returns 1 or True if the stream has views.  No caching since this could change.

=cut

sub hasViews {
    my $self = shift;
    my ($stdout) = $self->ct(['describe','-fmt','%[views]p',$self->specifier]);
    if (@$stdout) { return 1 } else { return 0 }
}

=head2 activity(name,...) -> ClearCase::Activity,...

=cut

sub activity {
    my $self = shift;
    return $self->pvob->activity(@_);
}

=head2 streamComponents -> ( ClearCase::StreamComponent,... )

=cut

memoize('streamComponents');
sub streamComponents {
    my $self = shift;
    my ($componentNames) = $self->ct(['describe',-fmt => '%[components]p\n',$self->specifier],leaveStderr=>1);
    foreach my $componentName (split(' ',$componentNames->[0])) {
	$self->{components}{$componentName} = _get ClearCase::StreamComponent $self,$componentName;
    }
    return values %{$self->{components}};
}

=head2 streamComponent -> ClearCase::StreamComponent

=cut

sub streamComponent {
    my $self = shift;
    $self->streamComponents();
    return $self->{@ARGV};
}

#######################################
#-- OPERATORS

=head2 mkactivity(<ct mkactivity options & args>) -> ClearCase::Activity

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mkactivity {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'mkactivity',
					-comment => 's',
					-headline => 's',
					-nset => '',
					);
    $cmd->prepare(@_,-in=>$self->specifier);
    my ($name) = $cmd->args;
    $cmd->run();

    return $cmd->retval unless $cmd->status;

    $self->{activities}->add($name);

    return $cmd->retval($self->activity($name)) if defined wantarray;
}

=head2 rmstream() -> 0 | 1

=cut

sub rmstream {
    my $self = shift;

    my ($status) = 
	$self->ct(['rmstream','-nc','-force',$self->specifier],leaveStdout=>1,leaveStderr=>1,returnFail=>1);

    return undef if $status != 0;

    $self->{parent}->forget($self->name);

    return 1;
}

###############################################################################
package ClearCase::StreamCollection;

our @ISA = qw(ClearCase::Collection ClearCase::ProjectVobThingMixin);

sub _getCommand {
        # Different command depending on whether we want all or some items
    my $self = shift;
    my @names = @_;

    my @wanted;

    if (@names) {
	# Want just some items
	@wanted = map { "stream:$_\@".$self->vob->name } @names;
    } else {
	# Want all items
	@wanted = ('-invob',$self->vob->name);
    }

    return('lsstream','-fmt',ClearCase::Stream->format,ClearCase::Stream->extraLsFlags,@wanted);
}

sub _nameField { 'Name' }

###############################################################################

=head1 ClearCase::StreamComponent

Represents a component in a stream.  Contains a list of stream component baselines.

=cut

package ClearCase::StreamComponent;

use Memoize qw(memoize);

our @ISA = qw(ClearCase::Thing ClearCase::ProjectVobThingMixin);

#######################################
# -- CONSTRUCTOR
sub _get {
    my $class = shift;
    my $parent = shift;
    my $componentName = shift;

    return bless {
	Name => $componentName,
	parent => $parent,
    }, $class;
}	

#######################################
#-- ACCESSORS

=head2 name() -> string

=cut

sub name { return $_[0]->{Name} }

=head2 component() -> ClearCase::Component

=cut

sub component { return $_[0]->pvob->component($_[0]->name) };

=head2 stream() -> ClearCase::Stream

=cut

sub stream { return $_[0]->{parent} }

=head2 baselines() -> ( ClearCase::Baseline,... )

=cut

memoize('baselines');
sub baselines {
    my $self = shift;
    my ($baselineNames) = $self->baselineNames();
    foreach my $baselineName (@$baselineNames) {
	$self->{baselines}{$baselineName} = $self->pvob->baseline($baselineName);
    }
    return values %{$self->{baselines}};

}

=head2 baselineNames() -> ( string,... )

Returns a list of the baseline names for the stream component.  Much faster
than the baselines() method.  Use this in combination with the baseline()
method.

=cut

memoize('baselineNames');
sub baselineNames {
    my $self = shift;
    ($self->{baselineNames}) = $self->ct(['lsbl','-short','-stream'=>,$self->stream->specifier,'-component'=>$self->component->specifier],leaveStderr=>1);
    return @{$self->{baselineNames}};
}

=head2 baseline() -> ClearCase::Baseline

Note - this takes just one baseline name as argument.

=cut

memoize('baseline');
sub baseline {
    my $self = shift;
    my $baselineName = shift;
    return $self->pvob->baseline($baselineName);
}



###############################################################################

=head1 ClearCase::Thing

Parent of all objects.  Provides several generic methods.

=cut

package ClearCase::Thing;

use Carp qw(cluck);

# Parent class for all classes representing things

use IO::Select;

# If the IO::Pty package exists, this allows us to assign a pseudo-tty
# to subprocesses in forkexec().
use constant HAS_IO_PTY => (eval "use IO::Pty") || !$@;

#######################################
#-- CLASS-PRIVATE DATA

# Class variables that should never change, so they may as well be hard-coded.
my $cleartool = '/opt/rational/clearcase/bin/cleartool';
my $clearprompt = '/opt/rational/clearcase/bin/clearprompt';
my $separator = '@@';
my $viewdir = "/view";   # Where views are mounted

=head1 separator() -> string

Returns the separator which is hard-coded in the module (i.e. you can't change
it) to '@@'.

=cut

sub separator { return $separator }

=head1 viewdir() -> string

Returns the path to the view filesystem mountpoint which is hard-coded in the module
(i.e. you can't change it) to '/view'.

=cut

sub viewdir { return $viewdir }

# Give all objects a 'cc' method which will recursively walk up the tree
# and eventually return the top ClearCase object.
sub cc { return $_[0]->{parent}->cc }

#######################################
#-- CONSTRUCTOR
#
# The constructor does not create a new thing, e.g. a new vob; instead
# it gets an object representing a pre-existing thing.  Therefore it is
# called 'get' instead of 'new'.  It also should only be called internally
# so it follows the convention of 'private methods start with underscore',
# where 'private' in this case means private to the overall package.

sub _get {
    my $class = shift;
    my $parent = shift;
    my $fields = shift;
    $fields->{parent} = $parent;
    return bless $fields, $class
}

sub parent { $_[0]->{parent} }

=head2 forkexec(...) -> ...

Class method to run a command.  First argument is an array hash containing
the command; remaining arguments is a list of pairs of named arg & value:

=over

=item returnFail

    Return failure if 1, otherwise die on failure; default = 0

=item verbose

    Print the command to be executed if 1; default = 0

=item debug

    Print the command to be executed and the exit status if 1; default = 0

=item leaveStdout

    Leave stdout alone, i.e. send it to the program stdout if set, otherwise
    capture it and return it to the caller; default = 0

=item splitStdout

    Split stdout into lines before returning it; no effect if leaveStdout is 1.

=item chompStdout

    Remove newlines from stdout before returning it; no effect if leaveStdout is 1
    or splitStdout is 0.

=item leaveStderr

    Leave stderr alone, i.e. send it to the program stderr if set, otherwise
    capture it and return it to the caller; default = 0

=item splitStderr

    Split stderr into lines before returning it; no effect if leaveStderr is 1.

=item chompStderr

    Remove newlines from stderr before returning it; no effect if leaveStderr is 1
    or splitStderr is 0.

=item pseudotty

    Set up a pseudo-tty for the child process.  Use this if you are having problems
    running a command from a crontab or other environment where there is normally
    no controlling tty.  With this, leaveStdout must be set to 0, and leaveStderr
    must be set to 1.  All output will be returned as stdout, and stderr will be
    empty.  This is because all output is going to the process's tty

=item environment

    Hash of environment variables to set

=back

Returns from zero to three arguments:

=over

=item

if returnFail is true, returns the status.  If this is zero, the command succeeded.

=item

if leaveStdout is false, returns stdout as an array reference with newlines removed.

=item

if leaveStderr is false, returns stderr as an array reference with newlines removed.

=back

=cut

sub forkexec {
    my $self = shift;
    my $command = shift;

    my %args = (
		'returnFail'=>0,
		'verbose'=>($ClearCase::VERBOSE >= 1),
		'debug'=>($ClearCase::DEBUG >= 1),
		'leaveStdout'=>0,
		'splitStdout'=>1,
		'chompStdout'=>1,
		'leaveStderr'=>0,
		'splitStderr'=>1,
		'chompStderr'=>1,
		'pseudotty'=>0,
                'environment'=>{},
		@_ );

    ($args{debug} || $args{verbose}) and print "Running command: @$command\n";

    my $master;

    if ($args{pseudotty}) {
	
	if (!HAS_IO_PTY) { die "Cannot call forkexec with pseudotty on this system; Perl module IO::Pty is not installed\n" }

	$master = new IO::Pty;
    }

    pipe(STDOUTREAD,STDOUTWRITE) unless $args{leaveStdout};
    pipe(STDERRREAD,STDERRWRITE) unless $args{leaveStderr};
    my $pid = fork();
    if ($pid) {
	# parent process
	close STDOUTWRITE unless $args{leaveStdout};
	close STDERRWRITE unless $args{leaveStderr};
	$master->close_slave if $args{pseudotty};

	# Drop through to the end
    } elsif (defined $pid) {
	# child process

	if ($args{pseudotty}) {
	    $ENV{TERM} = 'xterm';
	    $master->make_slave_controlling_terminal();
	    my $slave_fd = $master->fileno;
	    # These lines are left here to show how to use the new tty if needed
	    #$master->slave->clone_winsize_from(\*STDIN);
	    open STDIN, "<&$slave_fd" or die "Cannot dup stdin, $!";   # must redirect stdin from the new tty to get stty to work properly
	    #open STDOUT, ">&$slave_fd" or die "Cannot dup stdout, $!";
	    #open STDERR, ">&$slave_fd" or die "Cannot dup stdout, $!";
	    system('stty rows 24 cols 80');
	}

	# They may get redirected again later, bu
	close STDOUTREAD unless $args{leaveStdout};
	close STDERRREAD unless $args{leaveStderr};
	open STDOUT, ">&STDOUTWRITE" unless $args{leaveStdout};
	open STDERR, ">&STDERRWRITE" unless $args{leaveStderr};

	while (my($k,$v) = each %{$args{environment}}) {
	    if (!defined($v)) {
		delete $ENV{$k};
	    } else {
		$ENV{$k} = $v;
	    }
	}

	exec(@$command);

	die "Failed to exec, $!\n";
	
    } else {
	die "Failed to fork, $!\n";
    }

    my $selector = new IO::Select;
    $selector->add(fileno(STDOUTREAD)) unless $args{leaveStdout};
    $selector->add(fileno(STDERRREAD)) unless $args{leaveStderr};
    #$selector->add(fileno($master)) if $args{pseudotty};

    my $stdout = "";
    my $stdoutOffset = 0;

    my $stderr = "";
    my $stderrOffset = 0;

    while (my @ready = $selector->can_read) {
        foreach my $fh (@ready) {
            unless ($args{leaveStdout}) {
                if ($fh == fileno(STDOUTREAD)) {
                    while (my $read = sysread(STDOUTREAD,$stdout,1024,$stdoutOffset)) {
			$args{debug} && print substr $stdout,$stdoutOffset,$read;
                        $stdoutOffset += $read;
                    }
                }
            }
            unless ($args{leaveStderr}) {
                if ($fh == fileno(STDERRREAD)) {
                    my $read = sysread(STDERRREAD,$stderr,1024,$stderrOffset);
		    $args{debug} && print substr $stderr,$stderrOffset,$read;
		    $stderrOffset += $read;
                }
            }
            $selector->remove($fh) if eof($fh);
        }
    }

    waitpid($pid,0);

    my $signal = $? & 127;
    my $coredump = $? & 128;

    die "Command killed with signal $signal: @$command\n" if $signal;
    die "Command dumped core: @$command\n" if $coredump;

    my $status = $? >> 8;

    ($args{debug} || $args{verbose}) and print "Status: $status\n";

    if ($status && !$args{returnFail}) {
	die "Command @$command failed!\n";
    }

    my (@stdout,@stderr);

    unless ($args{leaveStdout}) {
	if ($args{splitStdout}) {
	    @stdout = split(/^/,$stdout);
	    if ($args{chompStdout}) {
		chomp(@stdout);
	    }
	}
    }
    unless ($args{leaveStderr}) {
	if ($args{splitStderr}) {
	    @stderr = split(/^/,$stderr);
	    if ($args{chompStderr}) {
		chomp(@stderr);
	    }
	}
    }

    # Only return the things that are expected.
    my @retval;

    push @retval, $status if $args{returnFail};

    unless ($args{leaveStdout}) {
	if ($args{splitStdout}) {
	    push @retval, \@stdout;
	} else {
	    push @retval, $stdout;
	}
    }

    unless ($args{leaveStderr}) {
	if ($args{splitStderr}) {
	    push @retval, \@stderr;
	} else {
	    push @retval, $stderr;
	}
    }

    return @retval;
}

=head2 cleartool -> path

Returns the path to cleartool.  You should normally use ct() instead to call cleartool

=cut

sub cleartool { return $cleartool }

=head2 ct(....) -> ...

Execute a cleartool command.  Same args as forkexec().

=cut

sub ct {
    my $self = shift;
    unshift @{$_[0]},$cleartool;
    return $self->forkexec(@_);
}

=head2 clearprompt(...) -> ...

Execute clearprompt command.  Same args as forkexec().

=cut

sub clearprompt {
    my $self = shift;
    unshift @{$_[0]},$clearprompt;
    return $self->forkexec(@_);
}

# _unpack takes one entry from _splitGetCommandOutput and creates a hash of
# item properties
sub _unpack {
    my $self = shift;
    my $output = shift;
    my %retval;
    foreach (@$output) {
	/\s*(.*?):\s*(.*)/ and $retval{$1} = $2;
    }
    return \%retval;
}

###############################################################################

=head1 ClearCase::Trigger;

A trigger.  Not fully implemented - note that you almost always want a trigger type,
not a trigger.

=cut

package ClearCase::Trigger;

our @ISA = qw(ClearCase::Thing ClearCase::VobThingMixin);

sub _get {
    my $class = shift;
    my $object = shift;
    my $trtype = shift;
    bless {
	object => $object,
	trtype => $trtype,
    }, $class;
}

#######################################
#-- DESTRUCTOR

=head2 rmtrigger(<ct rmtrigger options>) -> 0 | 1

Do not specify the trigger type or object name.

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub rmtrigger {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'rmtrigger',
					-comment => 's',
					-ninherit => '',
					-nattach => '',
					-recurse => '',
					);
    $cmd->prepare(@_);
    $cmd->setArgs($self->{trtype}->specifier,$self->{object}->specifier);
    $cmd->run();

    return $cmd->retval;
}

###############################################################################

=head1 ClearCase::TriggerMixin;

Provides trigger related methods to all objects that can have a trigger applied to
them.  Note that you normally want a trigger type, not a trigger.  This class
is not fully implemented, in particular you can't get a list of triggers.

=cut

package ClearCase::TriggerMixin;

=head2 mktrigger(<ct mktrigger options>, trtype) -> 0 | 1

You must specify the trtype.

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mktrigger {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'mktrigger',
					-comment => 's',
					-recurse => '',
					-ninherit => '',
					-nattach => '',
					-force => '',
					);
    $cmd->prepare(@_);
    my ($trtype) = $cmd->Args;
    $cmd->setArgs($cmd->Args, $self->specifier);
    $cmd->run();

    return $cmd->retval(_get ClearCase::Trigger $self, $trtype) if defined wantarray;
}

###############################################################################

=head1 ClearCase::TrType;

Inherits from ClearCase::Thing, ClearCase::RenameMixin, ClearCase::ProtectMixin, ClearCase::LockMixin, ClearCase::Type.

=cut

package ClearCase::TrType;
our @ISA = qw(ClearCase::Thing ClearCase::VobThingMixin ClearCase::RenameMixin ClearCase::ProtectMixin ClearCase::LockMixin ClearCase::Type);

sub format { 'Name: %n\nCreated: %d\nOwner: %u\nTrigger kind: %[trigger_kind]p\n\n' }

sub kind { 'trtype' }

#######################################
#-- ACCESSORS

=head2 name() -> string

=cut

sub name { return $_[0]->{Name} }

=head2 owner() -> string

=cut

sub owner { return $_[0]->{Owner} }

=head2 type() -> 'element trigger' | 'all element trigger' | 'type trigger'

=cut

sub type { return $_[0]->{'Trigger kind'} }

###############################################################################
package ClearCase::TrTypeCollection;

our @ISA = qw(ClearCase::TypeCollection);

###############################################################################

=head1 ClearCase::Type

Parent class for all Type classes, i.e. ClearCase::AtType, ClearCase::BrType,
ClearCase::HlType, ClearCase::LbType and ClearCase::TrType.  If element types
are supported, this will be the parent class for ClearCase::ElType too.  Provides
the specifier method and the rmtype method

=cut

package ClearCase::Type;

# Superclass for all types: attype, brtype, hltype, etc.

#######################################
#-- ACCESSORS

=head2 specifier() -> string

Returns the name of the type in the form '<type>:<name>@<vob>'

=cut

sub specifier {
    my $self = shift;
    return $self->kind.':'.$self->name.'@'.$self->vob->name;
}

sub vob { $_[0]->{vob} }

#######################################
#-- DESTRUCTOR

=head2 rmtype(<ct rmtype options>) => 0 | 1

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub rmtype {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'rmtype',
					'-rmall' => '',
					'-force' => '',
					'-ignore' => '',
					);
    $cmd->prepare(@_, $self->specifier);
    $cmd->run();

    return $cmd->retval unless $cmd->status;

    $self->{parent}->forget($self->name);

    return $cmd->retval;
}

###############################################################################
package ClearCase::TypeCollection;

# Abstract class that is parent for all type collection classes

our @ISA = qw(ClearCase::Collection ClearCase::VobThingMixin);

sub _getCommand {
    # Different command depending on whether we want all or some items
    my $self = shift;
    my @names = @_;

    my @wanted;

    if (@names) {
	# Want just some items
	@wanted = map { $self->{itemClass}->kind.":$_\@".$self->vob->name } @names;
    } else {
	# Want all items
	@wanted = ('-kind',$self->{itemClass}->kind,'-invob',$self->vob->name);
    }

    return('lstype','-fmt',$self->{itemClass}->format,$self->{itemClass}->extraLsFlags,@wanted);
}

sub _nameField { 'Name' }

###############################################################################
package ClearCase::UnionConfigRecord;
our @ISA = qw(ClearCase::ConfigRecord);

#######################################
#-- CONSTRUCTOR

###############################################################################
# TBD!

=head1 ClearCase::Version;

Inherits from ClearCase::Thing, ClearCase::TriggerMixin, ClearCase::LockMixin, ClearCase::AttributeMixin.
Currently, a very limited implementation.  Will be expanded.

=cut

package ClearCase::Version;

our @ISA = qw(ClearCase::Thing ClearCase::ViewThingMixin ClearCase::TriggerMixin ClearCase::LockMixin ClearCase::AttributeMixin);

#######################################
#-- CONSTRUCTOR

sub _get {
    my $class = shift;
    my $path = shift;
    my $oid = shift;
    my $version = shift;
    my $pred = shift;

    return bless {
	path => $path,
	oid => $oid,
	version => $version,
	pred => $pred,
    }, $class;
}

#######################################
#-- ACCESSORS

=head2 path() -> string

Returns the path in the current view, or undef if the element is not visible.

=cut

sub path {
    my $self = shift;
    # Extended path may end with CHECKEDOUT.12345, so remove that
    (my $extendedPath = $self->{path}) =~ s%CHECKEDOUT\.[0-9]+$%CHECKEDOUT%;
    my $version = $self->{version};
    
    # Remove the version from the extended path
    (my $path = $extendedPath) =~ s/$version$//;

    # If the path does not end with @@ in it, the element is not visible in this view
    return undef if $path !~ /\@\@$/;

    # Now remove the trailing @@
    $path =~ s/\@\@$//;

    return $path;
}

=head2 extendedPath() -> string

Returns the full path including element, branch and version.

=cut

sub extendedPath { $_[0]->{path} }

=head2 branchPath() -> string

Returns the branch portion of the extended version name.

=cut

sub branchPath {
    my $self = shift;
    (my $retval = $self->{version}) =~ s%/[0-9]+$%%;  # Strip off the trailing version number
    return $retval;
}

=head2 version() -> string

=cut

sub version { $_[0]->{version} }

=head2 versionNumber() -> string

For a checked-in version, returns the version number.  For checked-out versions
will return CHECKEDOUT, possibly with a numbered suffix, e.g CHECKEDOUT.132532

=cut
    
sub versionNumber {
    my $self = shift;
    (my $retval = $self->{version}) =~ s%.*/(.+)$%$1%;
    return $retval;
}

=head2 isCheckedOut() -> true|false

=cut

sub isCheckedOut { $_[0]->{version} =~ m%/CHECKEDOUT(\.[0-9]+)?$% }
    
=head2 predecessorVersion() -> string

=cut

sub predecessorVersion { $_[0]->{pred} }
    
#######################################
sub _getDetails {
    my $self = shift;
    return if exists $self->{details};
    my ($status,$stdout) =
	$self->ct(['describe',-fmt=>'Datetime: %d\nVersion: %Sn\nPredecessor: %Psn\nHost: %h\nUser: %u\nActivity: %[activity]p\nType: %[type]p\n\n',$self->{path}],returnFail=>1,leaveStderr=>1);
    $self->{details} = $self->_unpack($stdout);
}


=head2 datetime() -> string

=cut

sub datetime { $_[0]->_getDetails(); $_[0]->{details}{Datetime} }

=head2 host() -> ClearCase::Host

=cut

sub host { my $self = shift; $self->_getDetails(); $self->cc->host($self->{details}{Host}) }

=head2 user() -> string

=cut

sub user { $_[0]->_getDetails(); $_[0]->{details}{User} }

=head2 activity() -> ClearCase::Activity

=cut

sub activity { my $self = shift; $self->_getDetails(); $self->pvob->activity($self->{details}{Activity}) }

=head2 elementType() -> string

In the future this will be updated to return a ClearCase::ElType
=cut

sub elementType { $_[0]->_getDetails(); $_[0]->{details}{Type} }

=head2 predecessor() -> ClearCase::Version

=cut

sub predecessor {
    _get ClearCase::Version $_[0]->{details}{Predecessor};
}


=head2 specifier() -> string

Returns the name of the version.

=cut

sub specifier { $_[0]->{path} }

#######################################
#-- OPERATORS

=head2 annotate(<ct annotate options>) -> [ annotate stdout ]

=cut

sub annotate {
    my $self = shift;

    my ($status,$stdout) = $self->ct(['annotate',@_,$self->name],returnFail=>1,returnStdout=>1);

    return undef if $status != 0;

    return $stdout;
}

=head2 checkout([-comment=>$comment]) -> ClearCase::Checkout

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub checkout {
    my $self = shift;
    
    my $cmd = new ClearCase::Cleartool (
					'checkout',
					-comment => 's',
					);
    $cmd->prepare(@_, $self->path);
    $cmd->run();

    return $cmd->retval unless $cmd->status;
    return $cmd->retval($self->cc->cwv->lscheckout($self->path)) if defined wantarray;
}

=head2 mklabel(<ct mklabel options>) -> 0 | 1

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mklabel {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'mklabel',
					-comment => 's',
					-replace => '',
					-recurse => '',
					-follow => '',
					);
    $cmd->prepare(@_, $self->path);
    $cmd->run();
    return $cmd->retval;
}

###############################################################################

=head1 ClearCase::View;

Inherits from ClearCase::Thing

=cut

package ClearCase::View;

our @ISA = qw(ClearCase::Thing);

# Constructor is called 'get', since this doesn't create a new view but instead
# just gets view info into an object.
# All operations that checkout files or need checkouts, e.g. mkelem, mkdir, etc,
# belong to CurrentView - you can't do these things for any view that is not
# the current view.

use Cwd qw(abs_path);
use Memoize;
use Time::Local qw(timelocal);

#######################################
#-- CONSTRUCTOR

sub _get {
    my $class = shift;
    my $parent = shift;
    my $fields = shift;
    my $self = bless $fields,$class;

    $self->{parent} = $parent;

    $self->{checkout} = {};

    # View tag line for snapshot views that have been moved will contain
    # a comment with the original location, so clean it up if necessary
    $self->{Tag} =~ s/(.*?) \".*\"$/$1/;

    # Owner is in the form nisServer/username or Windows domain\username, so extract username.
    # If there is only a view tag and no underlying view object, there
    # will not be an owner
    if (!exists $fields->{'View owner'}) {
	$self->{owner} = undef;
    } elsif ($fields->{'View owner'} =~ m%.*/%) {
	($self->{owner} = $fields->{'View owner'}) =~ s%.*/%%;
    } elsif ($fields->{'View owner'} =~ m%.*\\%) {
	($self->{owner} = $fields->{'View owner'}) =~ s%.*\\%%;
    }

    if ($self->{'View attributes'}) {
	$self->{'View attributes'} = { map { $_ => 1 } split ' ',$self->{'View attributes'} };
    } else {
	$self->{'View attributes'} = {};
    }

    return $self;
}

#######################################
#-- ACCESSORS


=head2 name() -> string

=cut

sub name { return $_[0]->{Tag} }

=head2 owner() -> string | undef

If there is no view object, this will return undef.

=cut

sub owner { return $_[0]->{owner} }

=head2 isUcm() -> 0 | 1

=cut

sub isUcm { return $_[0]->{'View attributes'}{ucmview} }

=head2 ucm() -> 0 | 1

DEPRECATED - use isUcm() instead

=cut

sub ucm { return $_[0]->isUcm() }

=head2 isSnapshot() -> 0|1

=cut

sub isSnapshot { return defined($_[0]->{'View attributes'}{snapshot}) }

=head2 isDynamic() -> 0 | 1

=cut

sub isDynamic { return !defined($_[0]->{'View attributes'}{snapshot}) }

=head2 gpath() -> string

=cut

sub gpath { return $_[0]->{'Global path'} }

=head2 uuid() -> string

=cut

sub uuid { return $_[0]->{'View uuid'} }

=head2 serverHost() -> ClearCase::Host

=cut

sub serverHost { my $self = shift; $self->cc->host($self->{'Server host'}) }

=head2 region() -> ClearCase::Region

=cut

sub region { my $self = shift; $self->cc->region($self->{'Region'}) }

=head2 active() -> 0 | 1

=cut

sub active { return $_[0]->{Active} eq 'YES' }

=head2 tagUuid() -> string

=cut

sub tagUuid { return $_[0]->{'View tag uuid'} }

=head2 host() -> string

=cut

sub host { my $self = shift; $self->cc->host($self->{'View on host'}) }

=head2 hpath() -> string

=cut

sub hpath { return $_[0]->{'View server access path'} }

=head2 viewOwner() -> string

=cut

sub viewOwner { return $_[0]->{'View owner'} }

=head2 cs() -> config spec

=cut

#######################################
# Accessors for -prop -full properties

memoize('_getFullProps');
sub _getFullProps {
    my $self = shift;
    my ($status,$stdout,$stderr) = $self->ct(['lsview','-prop','-full',$self->name],returnFail=>1,leaveStdout=>0,leaveStderr=>0);
    return unless $status == 0;
    foreach (@$stdout) {
	if (/^(Created|Last modified|Last accessed|Last config spec update|Last view private object update) (.*?) by (.*)/) {
	    my ($field,$timestamp,$user) = ($1,$2,$3);
	    # Timestamp is in local timezone, so no need to allow for timezone info
	    if ($timestamp =~ /(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)/) {
		$self->{$field} = timelocal($6,$5,$4,$3,$2-1,$1);
		# For username remove everything after the first '.'
		($self->{"$field User"} = $user) =~ s/(.*?)\..*/$1/;
	    } else {
		die "Unknown timestamp format: $timestamp\n";
	    }
	}
    }
}

=head2 ctime() -> time | (time,username)

Returns the time that the view was created and, in array context, the last user.
cstime, ctime, mtime and atime all return time as seconds since the epoch.
This value can be passed to localtime() or compared to the return from
time().

=cut

sub ctime {
    my $self = shift;
    $self->_getFullProps;
    if (wantarray) {
	return $self->{Created},$self->{'Created User'};
    } else {
	return $self->{Created};
    }
}

=head2 mtime() -> time | (time,username)

Returns the time that the view was last modified, and, in array context, the last user.

=cut

sub mtime {
    my $self = shift;
    $self->_getFullProps;
    if (wantarray) {
	return $self->{'Last modified'},$self->{'Last modified User'};
    } else {
	return $self->{'Last modified'};
    }
}

=head2 atime() -> time | (time,username)

Returns the time that the view was last accessed, and, in array context, the last user.

=cut

sub atime {
    my $self = shift;
    $self->_getFullProps;
    if (wantarray) {
	return $self->{'Last accessed'},$self->{'Last accessed User'};
    } else {
	return $self->{'Last accessed'};
    }
}

=head2 cstime() -> time | (time,username)

Returns the time that the config spec was last updated, and, in array context, the last user.

=cut

sub cstime {
    my $self = shift;
    $self->_getFullProps;
    if (wantarray) {
	return $self->{'Last config spec update'},$self->{'Last config spec update User'};
    } else {
	return $self->{'Last config spec update'};
    }
}

=head2 vptime() -> time | (time,username)

Returns the time that the view private object was last updated, and, in array context, the last user.

=cut

sub vptime {
    my $self = shift;
    $self->_getFullProps;
    if (wantarray) {
	return $self->{'Last view private object update'},$self->{'Last view private object update User'},;
    } else {
	return $self->{'Last view private object update'};
    }
}

#######################################
# Accessors for 'ct space' details

memoize('_getSpace');
sub _getSpace {
    my $self = shift;
    my ($status,$stdout) = $self->ct(['space','-view',$self->name],returnFail=>1);
    if ($status == 0) {
	foreach (@$stdout) {
	    if (/^\s*(.*?)\s+.*?\%\s+(View private storage|View database|View administration data|Subtotal)/) {
		my ($size,$field) = ($1,$2);
		# Timestamp is in local timezone, so no need to allow for timezone info
		$self->{$field} = $size;
	    }
	}
    }
}

=head2 vpspace() -> float

Returns view private storage space in MB or undef if space is not available.

=cut

sub vpspace {
    my $self = shift;
    $self->_getSpace;
    return $self->{'View private storage'};
}
    
=head2 dbspace() -> float

Returns database space in MB or undef if space is not available.

=cut

sub dbspace {
    my $self = shift;
    $self->_getSpace;
    return $self->{'View database'};
}
    

=head2 adminspace() -> float

Returns view admin space in MB or undef if space is not available.

=cut

sub adminspace {
    my $self = shift;
    $self->_getSpace;
    return $self->{'View administration data'};
}
    

=head2 space() -> float

Returns total space used by view storage in MB or undef if space is not available.

=cut

sub space {
    my $self = shift;
    $self->_getSpace;
    return $self->{'Subtotal'};
}

#######################################
# other accessors

=head2 cs() -> [ cs-line,... ]

Returns a list of chomped lines containing the config spec

=cut

sub cs {
    my $self = shift;
    my ($status,$stdout) = $self->ct(['catcs','-tag',$self->name],returnFail=>1,leaveStderr=>1);
    return @$stdout;
}

=head2 cact() -> ClearCase::Activity

=cut

sub cact {
    my $self = shift;
    return undef if !$self->ucm();
    my ($status,$stdout) = $self->ct(['lsactivity','-cact',-fmt=>'%Xn',-view=>$self->name],returnFail=>1,leaveStderr=>1);
    return undef if $status != 0 || ! @$stdout;

    # Split the extended activity name into its parts
    my $extendedActivityName = $stdout->[0];
    $extendedActivityName =~ s/^activity://;   # Remove the leading "activity:" part
    my ($activity,$pvob) = split('@',$extendedActivityName);

    return $self->cc->pvob($pvob)->activity($activity);
}

sub _viewroot {
    my $self = shift;
    return $self->viewdir."/".$self->name;
}

sub _viewpath {
    my $self = shift;
    my $path = shift;
    return $self->viewdir."/".$self->name."/".$path;
}

=head2 version(path) -> ClearCase::Version

=cut

sub version {
    my $self = shift;
    my $path = shift;
    # The path can be:
    # - a relative path in the current view
    # - an absolute path in the current view
    # - an absolute path in a view that is not the current view.
    # We do not allow paths like '/view/viewname/vobs/...' to be passed to the
    # constructor...
    my $viewdir = $self->viewdir;
    if ($path =~ /^$viewdir/) {
	die "Cannot get a version object for a different view\n";
    }
    $path = abs_path($path);
    # only file or directory - not symlink or anything else
    if (! -f $self->_viewpath($path) && ! -d $self->_viewpath($path)) {
	die "Can only get a version object for an existing file or directory\n";
    }
    return _get ClearCase::Version $self,$path
}

# Lists checkouts as versions.  Does not cache any information
sub _lsco {
    my $self = shift;
    # lsco -avobs will FAIL if the view's config spec doesn't select any version for the mountpoint of any
    # vob, so use CLEARCASE_AVOBS to select just VOBs that are active and visible...
    my @visibleVobTags = grep { -d $self->viewdir."/".$self->name.$_ } map { $_->name } grep { $_->active } $self->cc->vobs;

    my ($stdout) = $self->ct(['setview','-exec',"$cleartool lsco -cview -avobs -fmt \"".$ClearCase::Checkout::format.'"',$self->name],splitStdout=>0,environment=>{CLEARCASE_AVOBS=>join(':',@visibleVobTags)});
    return $stdout;
}

sub _getCheckouts {
    my $self = shift;
    my @names = @_;
    
    if (@names) {
	my $gotAllNames = 1;
	foreach (@names) { $gotAllNames &&= exists $self->{checkout}{$_} }
	return if $gotAllNames;
    } else {
	return if $self->{'got-all-checkouts'};
    }

    my @wanted;

    my ($stdout) = $self->_lsco(@names);
    foreach (split /^\s*$/m, $stdout) {
	my $h = $self->_unpack([split('\n',$_)]);
	$self->{checkout}{$h->{Path}} = _get ClearCase::Checkout $self,$h;
    }

    $self->{'got-all-checkouts'} = 1 if !@names;
}

=head2 lscheckouts => ( ClearCase::Checkout,... )

=cut

sub lscheckouts {
    my $self = shift;
    $self->_getCheckouts();
    return values %{$self->{checkout}};
}

=head2 lscheckout(path) => ClearCase::Checkout | undef

=cut

# Can't call this checkout, since that will be the operator
sub lscheckout {
    my $self = shift;
    my $filename = shift;
    $self->_getCheckouts($filename);
    return $self->{checkout}{$filename};
}

=head2 lsprivate() -> filename,...

Lists all view-private files, including files, links, directories, derived objects, and checked-out files.
In the future this may be extended to take other options - in the meantime it takes the
mandatory -short option.

=cut

sub lsprivate {
    my $self = shift;

    my ($stdout) = $self->ct(['lsprivate','-short',-tag=>$self->name],returnFail=>0);
    my $viewname = $self->name;

    map { s%^/view/$viewname%% } @$stdout;    # Remove the /view/viewname from the paths

    return @$stdout;
}

=head2 stream() -> ClearCase::Stream

=cut

memoize('stream');
sub stream {
    my $self = shift;

    return undef if ! $self->isUcm;   # No stream if not a ucm view

    my ($status,$stdout) = $self->ct(['lsstream','-obsolete','-view',$self->name,'-fmt','%Xn\n'],returnFail=>1);
    # If the view is not accessible, the lsstream command will fail - treat this as the same as
    # not having a stream.
    return undef if $status != 0 || !@$stdout;
    $stdout->[0] =~ /^stream:(.*?)@(.*)/ or return undef;
    my ($streamname,$pvobname) = ($1,$2);

    return $self->cc->pvob($pvobname)->stream($streamname);
}

=head2 pvob() -> ClearCase::Pvob

=cut

memoize('pvob');
sub pvob {
    my $self = shift;

    return undef if ! $self->isUcm;   # No pvob if not a ucm view

    return $self->stream->pvob;
#    my ($status,$stdout) = $self->ct(['lsstream','-view',$self->name,'-fmt','%Xn\n'],returnFail=>1);
#    # If the view is not accessible, the lsstream command will fail - treat this as the same as
#    # not having a stream.
#    return undef if $status != 0;
#    $stdout->[0] =~ /^stream:(.*?)@(.*)/ or return undef;
#    my ($streamname,$pvobname) = ($1,$2);
#
#    return $self->cc->pvob($pvobname)->stream($streamname);
}


#######################################
#-- OPERATORS

=head2 setcs(config spec line,....) -> 0 | 1

Takes the config spec as a list of lines.  Newlines are optional.
Can also take a hash reference of options understood by forkexec(),
e.g.
$cc->cwv->setcs(@cs,{ leaveStdout => 0, returnFail => 1 });
This hash reference can be anywhere in the argument list.

=cut

use File::Temp qw(tempfile);

sub setcs {
    my $self = shift;

    # Go through arguments, extract hash reference if there is one
    my @cs;
    my %opts;
    my $userSpecifiedOpts = 0;
    foreach (@_) {
	if (ref($_) eq 'HASH') {
	    %opts = %$_;
	    $userSpecifiedOpts = 1;
	} elsif (ref($_)) {
	    die "Internal error: method setcs called with unknown argument type ".ref($_);
	} else {
	    push @cs, $_;
	}
    }

    if (!$userSpecifiedOpts) {
	# By default stdout and stderr should be unchanged
	%opts = ( leaveStdout => 1, leaveStderr => 1, returnFail => 0 );
    }

    my ($fh, $filename) = tempfile();

    print $fh map { "$_\n" } @cs;

    close $fh;

    my (@returns) = $self->ct(['setcs',-tag=>$self->name,$filename],%opts);

    unlink $filename;

    if ($userSpecifiedOpts) {
	return @returns;
    } else {
	return 1;  # Success, because otherwise ct() would die()
    }
}

=head2 setcsStream() -> 0 | 1

For a UCM view, sets the view\'s config spec to that defined by the stream it is attached to.

=cut

sub setcsStream {
    my $self = shift;

    my ($status) = $self->ct('setcs',-tag=>$self->name,'-stream');

    return ($status == 0);
}

=head2 setactivity(<ct setactivity options and arguments>, ClearCase::Activity) -> 0 | 1

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub setactivity {
    my $self = shift;
    my $cmd = new ClearCase::Cleartool (
					'setactivity',
					-comment => 's',
					);
    $cmd->prepare(@_,-view=>$self->name);
    $cmd->run();

    return $cmd->retval;
}

=head2 endview() -> 0 | 1

=cut

sub endview {
    my $self =shift;
    my ($status) = $self->ct(['endview',tag=>$self->name],leaveStdout=>1,leaveStderr=>1,returnFail=>1);
    return ($status == 0);
}

=head2 startview() -> 0 | 1

=cut

sub startview {
    my $self =shift;
    my ($status) = $self->ct(['startview',tag=>$self->name],leaveStdout=>1,leaveStderr=>1,returnFail=>1);
    return ($status == 0);
}

=head2 rmview() -> 0 | 1

=cut

sub rmview {
    my $self = shift;

    my ($status) = $self->ct(['rmview',-tag=>$self->name,'-force'],leaveStdout=>1,leaveStderr=>1,returnFail=>1);
    return undef if $status != 0;

    # If the same view is in multiple regions, it won't be removed from the other region ViewCollections
    $self->{parent}->forget($self->name);

    return 1;
}

=head2 unregister() -> 0 | 1

=cut

sub unregister {
    my $self = shift;

    my ($status) = $self->ct(['unregister',$self->path],leaveStdout=>1,leaveStderr=>1,returnFail=>1);

    return ($status == 0);
}

###############################################################################
package ClearCase::ViewCollection;

our @ISA = qw(ClearCase::Collection);

sub _getCommand {
    my $self = shift;
    # Need different command, if parent is ClearCase as opposed to Region
    if (ref $self->{parent} eq 'ClearCase:Region') {
	return ( 'lsview','-long','-region',$_[0]->{parent}->name );
    } else {
	return ( 'lsview','-long' );
    }
}

sub _nameField { 'Tag' }

###############################################################################
package ClearCase::ViewThingMixin;

# Mixin for things in a view, i.e. things with a view somewhere in their parentage
# Compare with ClearCase::VobThingMixin
sub view { $_[0]->{parent}->view }

###############################################################################

=head1 ClearCase::Vob

Inherits from ClearCase::Thing, ClearCase::RenameMixin, ClearCase::LockMixin, ClearCase::AttributeMixin.

=cut

package ClearCase::Vob;

use Memoize;
our @ISA = qw(ClearCase::Thing ClearCase::RenameMixin ClearCase::LockMixin ClearCase::AttributeMixin);

#######################################
#-- CONSTRUCTOR

sub _get {
    my $class = shift;
    my $parent = shift;
    my $fields = shift;
    my $self = $class->SUPER::_get($parent,$fields);
    $self->{attypes} = new ClearCase::AtTypeCollection $self;
    $self->{brtypes} = new ClearCase::BrTypeCollection $self;
    $self->{hltypes} = new ClearCase::HlTypeCollection $self;
    $self->{lbtypes} = new ClearCase::LbTypeCollection $self;
    $self->{trtypes} = new ClearCase::TrTypeCollection $self;
    return $self;
}

#######################################
#-- ACCESSORS


=head2 name() -> string

=cut

sub name { return $_[0]->{Tag} }

=head2 globalPath() -> string

=cut

sub globalPath { return $_[0]->{'Global path'} }

=head2 serverHost() -> ClearCase::Host

=cut

sub serverHost { my $self = shift; $self->cc->host($self->{'Server host'}) }

=head2 access() -> 'public' | 'private'

=cut

sub access { return $_[0]->{'Access'} }

=head2 mountOptions() -> string

=cut

sub mountOptions { return $_[0]->{'Mount options'} }

=head2 region() -> ClearCase::Region

=cut

sub region { my $self = shift; $self->cc->region($self->{'Region'}) }

=head2 active() -> 0 | 1

=cut

sub active { return $_[0]->{'Active'} eq 'YES' }

=head2 tagReplicaUuid() -> string

=cut

sub tagReplicaUuid { return $_[0]->{'Vob tag replica uuid'} }

=head2 host() -> ClearCase::Host

=cut

sub host { my $self = shift; $self->cc->host($self->{'Vob on host'}) }

=head2 serverAccessPath() -> string

=cut

sub serverAccessPath { return $_[0]->{'Vob server access path'} }

=head2 familyUuid() -> string

=cut

sub familyUuid { return $_[0]->{'Vob family uuid'} }

=head2 replicaUuid() -> string

=cut

sub replicaUuid { return $_[0]->{'Vob replica uuid'} }

sub vob { $_[0] }

=head2 specifier() -> string

Returns the name of the vob in the form 'vob:<name>'

=cut

sub specifier { 'vob:'.$_[0]->name }

sub adminVob {
    # TBD
}

=head2 owner() -> string

Returns the name of the vob owner

=cut

memoize('owner');
sub owner {
    my $self = shift;
    my ($status,$stdout,$stderr) = $self->ct(['describe',-fmt=>'%[owner]p',$self->specifier],returnFail=>1,leaveStdout=>0,leaveStderr=>0);
    return unless $status == 0;
    my $owner = $stdout->[0];
    # Remove any leading nis or domain info
    $owner =~ s%.*/%%;
    $owner =~ s%.*\\%%;
    return $owner;
}

=head2 attypes() -> ( ClearCase::AtType,... )

=cut

sub attypes { $_[0]->{attypes}->getAll };

=head2 attype(name,...) -> ClearCase::AtType,...

=cut

sub attype  { my $self = shift; $self->{attypes}->getOne(@_) };

=head2 brtypes() -> ( ClearCase::BrType,... )

=cut

sub brtypes { $_[0]->{brtypes}->getAll };

=head2 brtype(name,...) -> ClearCase::BrType,...

=cut

sub brtype  { my $self = shift; $self->{brtypes}->getOne(@_) };

=head2 hltypes() -> ( ClearCase::HlType,... )

=cut

sub hltypes { $_[0]->{hltypes}->getAll };

=head2 hltype(name,...) -> ClearCase::HlType,...

=cut

sub hltype  { my $self = shift; $self->{hltypes}->getOne(@_) };

=head2 lbtypes() -> ( ClearCase::LbType,... )

=cut

sub lbtypes { $_[0]->{lbtypes}->getAll };

=head2 lbtype(name,...) -> ClearCase::LbType,...

=cut

sub lbtype  { my $self = shift; $self->{lbtypes}->getOne(@_) };

=head2 trtypes() -> ( ClearCase::TrType,... )

=cut

sub trtypes { $_[0]->{trtypes}->getAll };

=head2 trtype(name,...) -> ClearCase::TrType,...

=cut

sub trtype  { my $self = shift; $self->{trtypes}->getOne(@_) };

#######################################
#-- OPERATORS

=head2 mkattype(<mkattype options & args>) => ClearCase::AtType

Only specify the type name; the vob name will be added automatically.

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mkattype {
    my $self = shift;
    my $cmd = new ClearCase::Cleartool (
					'mkattype',
					-comment => 's',
					-replace => '',
					-global => '',
					-acquire => '',    # Must have -global
					-ordinary => '',   # Cannot have -global and -ordinary
					-vp => 's',    # can be any one of element, branch, version
					-shared => '',
					-vtype => 's',  # can be any one of integer, real, time, string, opaque
					-gt => 's',
					-ge => 's',
					-lt => 's',
					-le => 's',
					-enum => 's',      # comma-separated values
					-default => 's',
					);
    $cmd->prepare(@_);
    my ($name) = $cmd->args;
    $cmd->setArgs('attype:'.$name.'@'.$self->name);
    $cmd->run();
    return $cmd->retval unless $cmd->status;
    $self->{attypes}->add($name);
    return $cmd->retval($self->attype($name)) if defined wantarray;
}

=head2 mkbrtype(<mkbrtype options & args>) => ClearCase::Brtype

Only specify the type name; the vob name will be added automatically.

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mkbrtype {
    my $self = shift;
    my $cmd = new ClearCase::Cleartool (
					'mkbrtype',
					-comment => 's',
					-replace => '',
					-global => '',
					-acquire => '',    # Must have -global
					-ordinary => '',   # Cannot have -global and -ordinary
					-pbranch => '',
					);
    $cmd->prepare(@_);
    my ($name) = $cmd->args;
    $cmd->setArgs('brtype:'.$name.'@'.$self->name);
    $cmd->run();
    return $cmd->retval unless $cmd->status;
    $self->{brtypes}->add($name);
    return $cmd->retval($self->brtype($name)) if defined wantarray;
}

=head2 mkhltype(<mkhltype options & args>) => ClearCase::Hltype

Only specify the type name; the vob name will be added automatically.

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mkhltype {
    my $self = shift;
    my $cmd = new ClearCase::Cleartool (
					'mkhltype',
					-comment => 's',
					-replace => '',
					-global => '',
					-acquire => '',    # Must have -global
					-ordinary => '',   # Cannot have -global and -ordinary
					-shared => '',
					);
    $cmd->prepare(@_);
    my ($name) = $cmd->args;
    $cmd->setArgs('hltype:'.$name.'@'.$self->name);
    $cmd->run();
    return $cmd->retval unless $cmd->status;
    $self->{hltypes}->add($name);
    return $cmd->retval($self->hltype($name)) if defined wantarray;
}

=head2 mklbtype(<mklbtype options & args>) => ClearCase::Lbtype

Only specify the type name; the vob name will be added automatically.

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mklbtype {
    my $self = shift;
    my $cmd = new ClearCase::Cleartool (
					'mklbtype',
					-comment => 's',
					-replace => '',
					-global => '',
					-acquire => '',    # Must have -global
					-ordinary => '',   # Cannot have -global and -ordinary
					-pbranch => '',
					-shared => '',
					);
    $cmd->prepare(@_);
    my ($name) = $cmd->args;
    $cmd->setArgs('lbtype:'.$name.'@'.$self->name);
    $cmd->run();
    return $cmd->retval unless $cmd->status;
    $self->{lbtypes}->add($name);
    return $cmd->retval($self->lbtype($name)) if defined wantarray;
}

=head2 mkelementrtype(<mktrtype options & args>) => ClearCase::TrType

Only specify the type name; the vob name will be added automatically.

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mkelementtrtype {
    my $self = shift;
    my $cmd = new ClearCase::Cleartool (
					'mktrtype',
					-comment => 's',
					-preop => 's',
					-postop => 's',
					-nusers => 's',
					-exec => 's',
					-execunix => 's',
					-execwin => 's',
					-mklabel => 's',
					-mkattr => 's',
					-mkhlink => 's',
					-from => 's',
					-to => 's',
					# restriction lists:
					-attype => 's',
					-brtype => 's',
					-eltype => 's',
					-hltype => 's',
					-lbtype => 's',
					-trtype => 's',
					);
    $cmd->prepare(@_);
    $cmd->setOpt(-element=>undef);
    my ($name) = $cmd->args;
    $cmd->setArgs('trtype:'.$name.'@'.$self->name);
    $cmd->run();
    return $cmd->retval unless $cmd->status;
    $self->{lbtypes}->add($name);
    return $cmd->retval($self->trtype($name)) if defined wantarray;
}

=head2 mktypetrtype(<mktrtype options & args>) => ClearCase::TrType

Only specify the type name; the vob name will be added automatically.

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mktypetrtype {
    my $self = shift;
    my $cmd = new ClearCase::Cleartool (
					'mktrtype',
					-comment => 's',
					-nusers => 's',
					-exec => 's',
					-execunix => 's',
					-execwin => 's',
					-mklabel => 's',
					-mkattr => 's',
					-mkhlink => 's',
					# inclusion lists:
					-attype => 's',
					-brtype => 's',
					-eltype => 's',
					-hltype => 's',
					-lbtype => 's',
					-trtype => 's',
					-print => '',
					);
    $cmd->prepare(@_);
    $cmd->setOpt(-type=>undef);
    my ($name) = $cmd->args;
    $cmd->setArgs('trtype:'.$name.'@'.$self->name);
    $cmd->run();
    return $cmd->retval unless $cmd->status;
    $self->{lbtypes}->add($name);
    return $cmd->retval($self->trtype($name)) if defined wantarray;
}

=head2 mkucmtrtype(<mktrtype options & args>) => ClearCase::TrType

Only specify the type name; the vob name will be added automatically.

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mkucmtrtype {
    my $self = shift;
    my $cmd = new ClearCase::Cleartool (
					'mktrtype',
					-comment => 's',
					-preop => 's',
					-postop => 's',
					-nusers => 's',
					-exec => 's',
					-execunix => 's',
					-execwin => 's',
					-mkattr => 's',
					-mkhlink => 's',
					#restriction list
					-component => 's',
					-project => 's',
					-stream => 's',
					-print => '',
					);
    $cmd->prepare(@_);
    $cmd->setOpt(-ucmobject=>undef);
    my ($name) = $cmd->args;
    $cmd->setArgs('trtype:'.$name.'@'.$self->name);
    $cmd->run();
    return $cmd->retval unless $cmd->status;
    $self->{lbtypes}->add($name);
    return $cmd->retval($self->trtype($name)) if defined wantarray;
}

=head2 mkucmbasetrtype(<mktrtype options & args>) => ClearCase::TrType

Only specify the type name; the vob name will be added automatically.

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mkucmbasetrtype {
    my $self = shift;
    my $cmd = new ClearCase::Cleartool (
					'mktrtype',
					-comment => 's',
					-preop => 's',
					-postop => 's',
					-nusers => 's',
					-exec => 's',
					-execunix => 's',
					-execwin => 's',
					-mkattr => 's',
					-mkhlink => 's',
					# restriction lists
					-component => 's',
					-project => 's',
					-stream => 's',
					-activity => 's',
					-baseline => 's',
					-folder => 's',
					-print => '',
					);
    $cmd->prepare(@_);
    $cmd->setOpt(-ucmobject=>undef);
    my ($name) = $cmd->args;
    $cmd->setArgs('trtype:'.$name.'@'.$self->name);
    $cmd->run();
    return $cmd->retval unless $cmd->status;
    $self->{lbtypes}->add($name);
    return $cmd->retval($self->trtype($name)) if defined wantarray;
}

=head2 mount(<ct mount options>) -> 0 | 1

One argument can be a hash reference with the same argument/value pairs that can be
passed to ClearCase::Thing->forkexec().

=cut

sub mount {
    my $self = shift;

    my $cmd = new ClearCase::Cleartool (
					'mount',
					-options => 's',
					);
    $cmd->prepare(@_);
    $cmd->setArgs($self->name);
    $cmd->run();
    return $cmd->retval;
}

=head2 umount() -> 0 | 1

=cut

sub umount {
    my $self = shift;
    my ($status) = $self->ct(['umount',$self->name],returnFail=>1);
    return ($status == 0);
}

=head2 rmview(ClearCase::View) -> 0 | 1

Remove view records from the vob.  See ClearCase::View->rmview to remove a view

=cut

sub rmview {
    my $self = shift;
    my $view = shift;

    my ($status) = $self->ct(['rmview','-force','-vob',$self->name,$view->uuid],leaveStdout=>1,leaveStderr=>1,returnFail=>1);
    return ($status == 0);
}

=head2 rmvob() -> 0 | 1

=cut

sub rmvob {
    my $self = shift;

    my ($status) = $self->ct(['rmvob','-force',$self->globalPath],leaveStdout=>1,leaveStderr=>1,returnFail=>1);
    return undef if $status != 0;

    # If the same vob is in multiple regions, it won't be removed from the other region VobCollections
    $self->{parent}->forget($self->name);

    return 1;
}

=head2 unregister() -> 0 | 1

=cut

sub unregister {
    my $self = shift;

    my ($status) = $self->ct(['unregister',$self->path],leaveStdout=>1,leaveStderr=>1,returnFail=>1);

    return ($status == 0);
}

###############################################################################
package ClearCase::VobCollection;

our @ISA = qw(ClearCase::Collection);

sub _getCommand {
    my $self = shift;
    # Need different command, if parent is ClearCase as opposed to Region
    if (ref $self->{parent} eq 'ClearCase:Region') {
	return ( 'lsvob','-long','-region',$_[0]->{parent}->name );
    } else {
	return ( 'lsvob','-long' );
    }
}

sub _nameField { 'Tag' }

###############################################################################

package ClearCase::VobThingMixin;

# Mixin for things in a vob, i.e. things with a vob somewhere in their parentage
# Compare with ClearCase::ViewThingMixin
sub vob { $_[0]->{parent}->vob }

sub extraLsFlags { () }

###############################################################################

