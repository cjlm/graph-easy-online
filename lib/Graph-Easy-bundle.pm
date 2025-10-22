#############################################################################
# A baseclass for Graph::Easy objects like nodes, edges etc.
#
#############################################################################

package Graph::Easy::Base;

$VERSION = '0.12';

use strict;

#############################################################################

{
  # protected vars
  my $id = 0;
  sub _new_id { $id++; }
  sub _reset_id { $id = 0; }
}

#############################################################################

sub new
  {
  # Create a new object. This is a generic routine that is inherited
  # by many other things like Edge, Cell etc.
  my $self = bless { id => _new_id() }, shift;

  my $args = $_[0];
  $args = { name => $_[0] } if ref($args) ne 'HASH' && @_ == 1;
  $args = { @_ } if ref($args) ne 'HASH' && @_ > 1;
 
  $self->_init($args);
  }

sub _init
  {
  # Generic init routine, to be overriden in subclasses.
  my ($self,$args) = @_;
  
  $self;
  }

sub self
  {
  my $self = shift;
  
  $self;
  }  

#############################################################################

sub no_fatal_errors
  {
  my $self = shift;

  $self->{fatal_errors} = ($_[1] ? 1 : 0) if @_ > 0;

  ~ ($self->{fatal_errors} || 0);
  }

sub fatal_errors
  {
  my $self = shift;

  $self->{fatal_errors} = ($_[1] ? 0 : 1) if @_ > 0;

  $self->{fatal_errors} || 0;
  }

sub error
  {
  my $self = shift;

  # If we switched to a temp. Graphviz parser, then set the error on the
  # original parser object, too:
  $self->{_old_self}->error(@_) if ref($self->{_old_self});

  # if called on a member on a graph, call error() on the graph itself:
  return $self->{graph}->error(@_) if ref($self->{graph});

  if (defined $_[0])
    {
    $self->{error} = $_[0];
    if ($self->{_catch_errors})
      {
      push @{$self->{_errors}}, $self->{error};
      }
    else
      {
      $self->_croak($self->{error}, 2)
        if ($self->{fatal_errors}) && $self->{error} ne '';
      }
    }
  $self->{error} || '';
  }

sub error_as_html
  {
  # return error() properly escaped
  my $self = shift;

  my $msg = $self->{error};

  $msg =~ s/&/&amp;/g;
  $msg =~ s/</&lt;/g;
  $msg =~ s/>/&gt;/g;
  $msg =~ s/"/&quot;/g;

  $msg; 
  }

sub catch_messages
  {
  # Catch all warnings (and errors if no_fatal_errors() was used)
  # these can later be retrieved with warnings() and errors():
  my $self = shift;

  if (@_ > 0)
    {
    if ($_[0])
      {
      $self->{_catch_warnings} = 1;
      $self->{_catch_errors} = 1;
      $self->{_warnings} = [];
      $self->{_errors} = [];
      }
    else
      {
      $self->{_catch_warnings} = 0;
      $self->{_catch_errors} = 0;
      }
    }
  $self;
  }

sub catch_warnings
  {
  # Catch all warnings
  # these can later be retrieved with warnings():
  my $self = shift;

  if (@_ > 0)
    {
    if ($_[0])
      {
      $self->{_catch_warnings} = 1;
      $self->{_warnings} = [];
      }
    else
      {
      $self->{_catch_warnings} = 0;
      }
    }
  $self->{_catch_warnings};
  }

sub catch_errors
  {
  # Catch all errors
  # these can later be retrieved with errors():
  my $self = shift;

  if (@_ > 0)
    {
    if ($_[0])
      {
      $self->{_catch_errors} = 1;
      $self->{_errors} = [];
      }
    else
      {
      $self->{_catch_errors} = 0;
      }
    }
  $self->{_catch_errors};
  }

sub warnings
  {
  # return all warnings that occured after catch_messages(1)
  my $self = shift;

  @{$self->{_warnings}};
  }

sub errors
  {
  # return all errors that occured after catch_messages(1)
  my $self = shift;

  @{$self->{_errors}};
  }

sub warn
  {
  my ($self, $msg) = @_;

  if ($self->{_catch_warnings})
    {
    push @{$self->{_warnings}}, $msg;
    }
  else
    {
    require Carp;
    Carp::carp('Warning: ' . $msg);
    }
  }

sub _croak
  {
  my ($self, $msg, $level) = @_;
  $level = 1 unless defined $level;

  require Carp;
  if (ref($self) && $self->{debug})
    {
    $Carp::CarpLevel = $level;			# don't report Base itself
    Carp::confess($msg);
    }
  else
    {
    Carp::croak($msg);
    }
  }
 
#############################################################################
# class management

sub sub_class
  {
  # get/set the subclass
  my $self = shift;

  if (defined $_[0])
    {
    $self->{class} =~ s/\..*//;		# nix subclass
    $self->{class} .= '.' . $_[0];	# append new one
    delete $self->{cache};
    $self->{cache}->{subclass} = $_[0];
    $self->{cache}->{class} = $self->{class};
    return;
    }
  $self->{class} =~ /\.(.*)/;

  return $1 if defined $1;

  return $self->{cache}->{subclass} if defined $self->{cache}->{subclass}; 

  # Subclass not defined, so check our base class for a possible set class
  # attribute and return this:

  # take a shortcut
  my $g = $self->{graph};
  if (defined $g)
    {
    my $subclass = $g->{att}->{$self->{class}}->{class};
    $subclass = '' unless defined $subclass;
    $self->{cache}->{subclass} = $subclass;
    $self->{cache}->{class} = $self->{class};
    return $subclass;
    }

  # not part of a graph?
  $self->{cache}->{subclass} = $self->attribute('class');
  }

sub class
  {
  # return our full class name like "node.subclass" or "node"
  my $self = shift;

  $self->error("class() method does not take arguments") if @_ > 0;

  $self->{class} =~ /\.(.*)/;

  return $self->{class} if defined $1;

  return $self->{cache}->{class} if defined $self->{cache}->{class};

  # Subclass not defined, so check our base class for a possible set class
  # attribute and return this:

  my $subclass;
  # take a shortcut:
  my $g = $self->{graph};
  if (defined $g)
    {
    $subclass = $g->{att}->{$self->{class}}->{class};
    $subclass = '' unless defined $subclass;
    }

  $subclass = $self->{att}->{class} unless defined $subclass;
  $subclass = '' unless defined $subclass;
  $self->{cache}->{subclass} = $subclass;
  $subclass = '.' . $subclass if $subclass ne '';

  $self->{cache}->{class} = $self->{class} . $subclass;
  }

sub main_class
  {
  my $self = shift;

  $self->{class} =~ /^(.+?)(\.|\z)/;	# extract first part

  $1;
  }

1;
__END__

=head1 NAME

Graph::Easy::Base - base class for Graph::Easy objects like nodes, edges etc

=head1 SYNOPSIS

	package Graph::Easy::My::Node;
	use Graph::Easy::Base;
	@ISA = qw/Graph::Easy::Base/;

=head1 DESCRIPTION

Used automatically and internally by L<Graph::Easy> - should not be used
directly.

=head1 METHODS

=head2 new()

	my $object = Graph::Easy::Base->new();

Create a new object, and call C<_init()> on it.

=head2 error()

	$last_error = $object->error();

	$object->error($error);			# set new messags
	$object->error('');			# clear the error

Returns the last error message, or '' for no error.

When setting a new error message, C<< $self->_croak($error) >> will be called
unless C<< $object->no_fatal_errors() >> is true.

=head2 error_as_html()

	my $error = $object->error_as_html();

Returns the same error message as L<error()>, but properly escaped
as HTML so it is safe to output to the client.

=head2 warn()

	$object->warn('Warning!');

Warn on STDERR with the given message.

=head2 no_fatal_errors()

	$object->no_fatal_errors(1);

Set the flag that determines whether setting an error message
via C<error()> is fatal, e.g. results in a call to C<_croak()>.

A true value will make errors non-fatal. See also L<fatal_errors>.

=head2 fatal_errors()

	$fatal = $object->fatal_errors();
	$object->fatal_errors(0);		# turn off
	$object->fatal_errors(1);		# turn on

Set/get the flag that determines whether setting an error message
via C<error()> is fatal, e.g. results in a call to C<_croak()>.

A true value makes errors fatal.

=head2 catch_errors()

	my $catch_errors = $object->catch_errors();	# query
	$object->catch_errors(1);			# enable

	$object->...();					# some error
	if ($object->error())
	  {
	  my @errors = $object->errors();		# retrieve
	  }

Enable/disable catching of all error messages. When enabled,
all previously caught error messages are thrown away, and from this
poin on new errors are non-fatal and stored internally. You can
retrieve these errors later with the errors() method.

=head2 catch_warnings()

	my $catch_warns = $object->catch_warnings();	# query
	$object->catch_warnings(1);			# enable

	$object->...();					# some error
	if ($object->warning())
	  {
	  my @warnings = $object->warnings();		# retrieve
	  }

Enable/disable catching of all warnings. When enabled, all previously
caught warning messages are thrown away, and from this poin on new
warnings are stored internally. You can retrieve these errors later
with the errors() method.

=head2 catch_messages()

	# catch errors and warnings
	$object->catch_messages(1);
	# stop catching errors and warnings
	$object->catch_messages(0);

A true parameter is equivalent to:

	$object->catch_warnings(1);
	$object->catch_errors(1);
	
See also: L<catch_warnings()> and L<catch_errors()> as well as
L<errors()> and L<warnings()>.

=head2 errors()

	my @errors = $object->errors();

Return all error messages that occured after L<catch_messages()> was
called.

=head2 warnings()

	my @warnings = $object->warnings();

Return all warning messages that occured after L<catch_messages()>
or L<catch_errors()> was called.

=head2 self()

	my $self = $object->self();

Returns the object itself.

=head2 class()

	my $class = $object->class();

Returns the full class name like C<node.cities>. See also C<sub_class>.

=head2 sub_class()

	my $sub_class = $object->sub_class();

Returns the sub class name like C<cities>. See also C<class>.

=head2 main_class()

	my $main_class = $object->main_class();

Returns the main class name like C<node>. See also C<sub_class>.

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2008 by Tels L<http://bloodgate.com>.

See the LICENSE file for more details.

X<tels>
X<bloodgate>
X<license>
X<gpl>

=cut
#############################################################################
# Define and check attributes for a Graph::Easy textual description.
#
#############################################################################

package Graph::Easy::Attributes;

$VERSION = '0.32';

package Graph::Easy;

use strict;
use utf8;		# for examples like "Fähre"

# to make it easier to remember the attribute names:
my $att_aliases = {
  'auto-label' => 'autolabel',
  'auto-link' => 'autolink',
  'auto-title' => 'autotitle',
  'arrow-style' => 'arrowstyle',
  'arrow-shape' => 'arrowshape',
  'border-color' => 'bordercolor',
  'border-style' => 'borderstyle',
  'border-width' => 'borderwidth',
  'font-size' => 'fontsize',
  'label-color' => 'labelcolor',
  'label-pos' => 'labelpos',
  'text-style' => 'textstyle',
  'text-wrap' => 'textwrap',
  'point-style' => 'pointstyle',
  'point-shape' => 'pointshape',
  };

sub _att_aliases { $att_aliases; }

#############################################################################
# color handling

# The W3C/SVG/CSS color scheme

my $color_names = {
  w3c =>
  {
  inherit		=> 'inherit',
  aliceblue             => '#f0f8ff',
  antiquewhite          => '#faebd7',
  aquamarine            => '#7fffd4',
  aqua                  => '#00ffff',
  azure                 => '#f0ffff',
  beige                 => '#f5f5dc',
  bisque                => '#ffe4c4',
  black                 => '#000000',
  blanchedalmond        => '#ffebcd',
  blue                  => '#0000ff',
  blueviolet            => '#8a2be2',
  brown                 => '#a52a2a',
  burlywood             => '#deb887',
  cadetblue             => '#5f9ea0',
  chartreuse            => '#7fff00',
  chocolate             => '#d2691e',
  coral                 => '#ff7f50',
  cornflowerblue        => '#6495ed',
  cornsilk              => '#fff8dc',
  crimson               => '#dc143c',
  cyan                  => '#00ffff',
  darkblue              => '#00008b',
  darkcyan              => '#008b8b',
  darkgoldenrod         => '#b8860b',
  darkgray              => '#a9a9a9',
  darkgreen             => '#006400',
  darkgrey              => '#a9a9a9',
  darkkhaki             => '#bdb76b',
  darkmagenta           => '#8b008b',
  darkolivegreen        => '#556b2f',
  darkorange            => '#ff8c00',
  darkorchid            => '#9932cc',
  darkred               => '#8b0000',
  darksalmon            => '#e9967a',
  darkseagreen          => '#8fbc8f',
  darkslateblue         => '#483d8b',
  darkslategray         => '#2f4f4f',
  darkslategrey         => '#2f4f4f',
  darkturquoise         => '#00ced1',
  darkviolet            => '#9400d3',
  deeppink              => '#ff1493',
  deepskyblue           => '#00bfff',
  dimgray               => '#696969',
  dodgerblue            => '#1e90ff',
  firebrick             => '#b22222',
  floralwhite           => '#fffaf0',
  forestgreen           => '#228b22',
  fuchsia               => '#ff00ff',
  gainsboro             => '#dcdcdc',
  ghostwhite            => '#f8f8ff',
  goldenrod             => '#daa520',
  gold                  => '#ffd700',
  gray                  => '#808080',
  green                 => '#008000',
  greenyellow           => '#adff2f',
  grey                  => '#808080',
  honeydew              => '#f0fff0',
  hotpink               => '#ff69b4',
  indianred             => '#cd5c5c',
  indigo                => '#4b0082',
  ivory                 => '#fffff0',
  khaki                 => '#f0e68c',
  lavenderblush         => '#fff0f5',
  lavender              => '#e6e6fa',
  lawngreen             => '#7cfc00',
  lemonchiffon          => '#fffacd',
  lightblue             => '#add8e6',
  lightcoral            => '#f08080',
  lightcyan             => '#e0ffff',
  lightgoldenrodyellow  => '#fafad2',
  lightgray             => '#d3d3d3',
  lightgreen            => '#90ee90',
  lightgrey             => '#d3d3d3',
  lightpink             => '#ffb6c1',
  lightsalmon           => '#ffa07a',
  lightseagreen         => '#20b2aa',
  lightskyblue          => '#87cefa',
  lightslategray        => '#778899',
  lightslategrey        => '#778899',
  lightsteelblue        => '#b0c4de',
  lightyellow           => '#ffffe0',
  limegreen             => '#32cd32',
  lime			=> '#00ff00',
  linen                 => '#faf0e6',
  magenta               => '#ff00ff',
  maroon                => '#800000',
  mediumaquamarine      => '#66cdaa',
  mediumblue            => '#0000cd',
  mediumorchid          => '#ba55d3',
  mediumpurple          => '#9370db',
  mediumseagreen        => '#3cb371',
  mediumslateblue       => '#7b68ee',
  mediumspringgreen     => '#00fa9a',
  mediumturquoise       => '#48d1cc',
  mediumvioletred       => '#c71585',
  midnightblue          => '#191970',
  mintcream             => '#f5fffa',
  mistyrose             => '#ffe4e1',
  moccasin              => '#ffe4b5',
  navajowhite           => '#ffdead',
  navy                  => '#000080',
  oldlace               => '#fdf5e6',
  olivedrab             => '#6b8e23',
  olive                 => '#808000',
  orangered             => '#ff4500',
  orange                => '#ffa500',
  orchid                => '#da70d6',
  palegoldenrod         => '#eee8aa',
  palegreen             => '#98fb98',
  paleturquoise         => '#afeeee',
  palevioletred         => '#db7093',
  papayawhip            => '#ffefd5',
  peachpuff             => '#ffdab9',
  peru                  => '#cd853f',
  pink                  => '#ffc0cb',
  plum                  => '#dda0dd',
  powderblue            => '#b0e0e6',
  purple                => '#800080',
  red                   => '#ff0000',
  rosybrown             => '#bc8f8f',
  royalblue             => '#4169e1',
  saddlebrown           => '#8b4513',
  salmon                => '#fa8072',
  sandybrown            => '#f4a460',
  seagreen              => '#2e8b57',
  seashell              => '#fff5ee',
  sienna                => '#a0522d',
  silver                => '#c0c0c0',
  skyblue               => '#87ceeb',
  slateblue             => '#6a5acd',
  slategray             => '#708090',
  slategrey             => '#708090',
  snow                  => '#fffafa',
  springgreen           => '#00ff7f',
  steelblue             => '#4682b4',
  tan                   => '#d2b48c',
  teal                  => '#008080',
  thistle               => '#d8bfd8',
  tomato                => '#ff6347',
  turquoise             => '#40e0d0',
  violet                => '#ee82ee',
  wheat                 => '#f5deb3',
  white                 => '#ffffff',
  whitesmoke            => '#f5f5f5',
  yellowgreen           => '#9acd32',
  yellow                => '#ffff00',
  },

  x11 => {
    inherit		=> 'inherit',
    aliceblue		=> '#f0f8ff',
    antiquewhite	=> '#faebd7',
    antiquewhite1	=> '#ffefdb',
    antiquewhite2	=> '#eedfcc',
    antiquewhite3	=> '#cdc0b0',
    antiquewhite4	=> '#8b8378',
    aquamarine		=> '#7fffd4',
    aquamarine1		=> '#7fffd4',
    aquamarine2		=> '#76eec6',
    aquamarine3		=> '#66cdaa',
    aquamarine4		=> '#458b74',
    azure		=> '#f0ffff',
    azure1		=> '#f0ffff',
    azure2		=> '#e0eeee',
    azure3		=> '#c1cdcd',
    azure4		=> '#838b8b',
    beige		=> '#f5f5dc',
    bisque		=> '#ffe4c4',
    bisque1		=> '#ffe4c4',
    bisque2		=> '#eed5b7',
    bisque3		=> '#cdb79e',
    bisque4		=> '#8b7d6b',
    black		=> '#000000',
    blanchedalmond	=> '#ffebcd',
    blue		=> '#0000ff',
    blue1		=> '#0000ff',
    blue2		=> '#0000ee',
    blue3		=> '#0000cd',
    blue4		=> '#00008b',
    blueviolet		=> '#8a2be2',
    brown		=> '#a52a2a',
    brown1		=> '#ff4040',
    brown2		=> '#ee3b3b',
    brown3		=> '#cd3333',
    brown4		=> '#8b2323',
    burlywood		=> '#deb887',
    burlywood1		=> '#ffd39b',
    burlywood2		=> '#eec591',
    burlywood3		=> '#cdaa7d',
    burlywood4		=> '#8b7355',
    cadetblue		=> '#5f9ea0',
    cadetblue1		=> '#98f5ff',
    cadetblue2		=> '#8ee5ee',
    cadetblue3		=> '#7ac5cd',
    cadetblue4		=> '#53868b',
    chartreuse		=> '#7fff00',
    chartreuse1		=> '#7fff00',
    chartreuse2		=> '#76ee00',
    chartreuse3		=> '#66cd00',
    chartreuse4		=> '#458b00',
    chocolate		=> '#d2691e',
    chocolate1		=> '#ff7f24',
    chocolate2		=> '#ee7621',
    chocolate3		=> '#cd661d',
    chocolate4		=> '#8b4513',
    coral		=> '#ff7f50',
    coral1		=> '#ff7256',
    coral2		=> '#ee6a50',
    coral3		=> '#cd5b45',
    coral4		=> '#8b3e2f',
    cornflowerblue	=> '#6495ed',
    cornsilk		=> '#fff8dc',
    cornsilk1		=> '#fff8dc',
    cornsilk2		=> '#eee8cd',
    cornsilk3		=> '#cdc8b1',
    cornsilk4		=> '#8b8878',
    crimson		=> '#dc143c',
    cyan		=> '#00ffff',
    cyan1		=> '#00ffff',
    cyan2		=> '#00eeee',
    cyan3		=> '#00cdcd',
    cyan4		=> '#008b8b',
    darkgoldenrod	=> '#b8860b',
    darkgoldenrod1	=> '#ffb90f',
    darkgoldenrod2	=> '#eead0e',
    darkgoldenrod3	=> '#cd950c',
    darkgoldenrod4	=> '#8b6508',
    darkgreen		=> '#006400',
    darkkhaki		=> '#bdb76b',
    darkolivegreen	=> '#556b2f',
    darkolivegreen1	=> '#caff70',
    darkolivegreen2	=> '#bcee68',
    darkolivegreen3	=> '#a2cd5a',
    darkolivegreen4	=> '#6e8b3d',
    darkorange		=> '#ff8c00',
    darkorange1		=> '#ff7f00',
    darkorange2		=> '#ee7600',
    darkorange3		=> '#cd6600',
    darkorange4		=> '#8b4500',
    darkorchid		=> '#9932cc',
    darkorchid1		=> '#bf3eff',
    darkorchid2		=> '#b23aee',
    darkorchid3		=> '#9a32cd',
    darkorchid4		=> '#68228b',
    darksalmon		=> '#e9967a',
    darkseagreen	=> '#8fbc8f',
    darkseagreen1	=> '#c1ffc1',
    darkseagreen2	=> '#b4eeb4',
    darkseagreen3	=> '#9bcd9b',
    darkseagreen4	=> '#698b69',
    darkslateblue	=> '#483d8b',
    darkslategray	=> '#2f4f4f',
    darkslategray1	=> '#97ffff',
    darkslategray2	=> '#8deeee',
    darkslategray3	=> '#79cdcd',
    darkslategray4	=> '#528b8b',
    darkslategrey	=> '#2f4f4f',
    darkturquoise	=> '#00ced1',
    darkviolet		=> '#9400d3',
    deeppink		=> '#ff1493',
    deeppink1		=> '#ff1493',
    deeppink2		=> '#ee1289',
    deeppink3		=> '#cd1076',
    deeppink4		=> '#8b0a50',
    deepskyblue		=> '#00bfff',
    deepskyblue1	=> '#00bfff',
    deepskyblue2	=> '#00b2ee',
    deepskyblue3	=> '#009acd',
    deepskyblue4	=> '#00688b',
    dimgray		=> '#696969',
    dimgrey		=> '#696969',
    dodgerblue		=> '#1e90ff',
    dodgerblue1		=> '#1e90ff',
    dodgerblue2		=> '#1c86ee',
    dodgerblue3		=> '#1874cd',
    dodgerblue4		=> '#104e8b',
    firebrick		=> '#b22222',
    firebrick1		=> '#ff3030',
    firebrick2		=> '#ee2c2c',
    firebrick3		=> '#cd2626',
    firebrick4		=> '#8b1a1a',
    floralwhite		=> '#fffaf0',
    forestgreen		=> '#228b22',
    gainsboro		=> '#dcdcdc',
    ghostwhite		=> '#f8f8ff',
    gold		=> '#ffd700',
    gold1		=> '#ffd700',
    gold2		=> '#eec900',
    gold3		=> '#cdad00',
    gold4		=> '#8b7500',
    goldenrod		=> '#daa520',
    goldenrod1		=> '#ffc125',
    goldenrod2		=> '#eeb422',
    goldenrod3		=> '#cd9b1d',
    goldenrod4		=> '#8b6914',
    gray		=> '#c0c0c0',
    gray0		=> '#000000',
    gray1		=> '#030303',
    gray2		=> '#050505',
    gray3		=> '#080808',
    gray4		=> '#0a0a0a',
    gray5		=> '#0d0d0d',
    gray6		=> '#0f0f0f',
    gray7		=> '#121212',
    gray8		=> '#141414',
    gray9		=> '#171717',
    gray10		=> '#1a1a1a',
    gray11		=> '#1c1c1c',
    gray12		=> '#1f1f1f',
    gray13		=> '#212121',
    gray14		=> '#242424',
    gray15		=> '#262626',
    gray16		=> '#292929',
    gray17		=> '#2b2b2b',
    gray18		=> '#2e2e2e',
    gray19		=> '#303030',
    gray20		=> '#333333',
    gray21		=> '#363636',
    gray22		=> '#383838',
    gray23		=> '#3b3b3b',
    gray24		=> '#3d3d3d',
    gray25		=> '#404040',
    gray26		=> '#424242',
    gray27		=> '#454545',
    gray28		=> '#474747',
    gray29		=> '#4a4a4a',
    gray30		=> '#4d4d4d',
    gray31		=> '#4f4f4f',
    gray32		=> '#525252',
    gray33		=> '#545454',
    gray34		=> '#575757',
    gray35		=> '#595959',
    gray36		=> '#5c5c5c',
    gray37		=> '#5e5e5e',
    gray38		=> '#616161',
    gray39		=> '#636363',
    gray40		=> '#666666',
    gray41		=> '#696969',
    gray42		=> '#6b6b6b',
    gray43		=> '#6e6e6e',
    gray44		=> '#707070',
    gray45		=> '#737373',
    gray46		=> '#757575',
    gray47		=> '#787878',
    gray48		=> '#7a7a7a',
    gray49		=> '#7d7d7d',
    gray50		=> '#7f7f7f',
    gray51		=> '#828282',
    gray52		=> '#858585',
    gray53		=> '#878787',
    gray54		=> '#8a8a8a',
    gray55		=> '#8c8c8c',
    gray56		=> '#8f8f8f',
    gray57		=> '#919191',
    gray58		=> '#949494',
    gray59		=> '#969696',
    gray60		=> '#999999',
    gray61		=> '#9c9c9c',
    gray62		=> '#9e9e9e',
    gray63		=> '#a1a1a1',
    gray64		=> '#a3a3a3',
    gray65		=> '#a6a6a6',
    gray66		=> '#a8a8a8',
    gray67		=> '#ababab',
    gray68		=> '#adadad',
    gray69		=> '#b0b0b0',
    gray70		=> '#b3b3b3',
    gray71		=> '#b5b5b5',
    gray72		=> '#b8b8b8',
    gray73		=> '#bababa',
    gray74		=> '#bdbdbd',
    gray75		=> '#bfbfbf',
    gray76		=> '#c2c2c2',
    gray77		=> '#c4c4c4',
    gray78		=> '#c7c7c7',
    gray79		=> '#c9c9c9',
    gray80		=> '#cccccc',
    gray81		=> '#cfcfcf',
    gray82		=> '#d1d1d1',
    gray83		=> '#d4d4d4',
    gray84		=> '#d6d6d6',
    gray85		=> '#d9d9d9',
    gray86		=> '#dbdbdb',
    gray87		=> '#dedede',
    gray88		=> '#e0e0e0',
    gray89		=> '#e3e3e3',
    gray90		=> '#e5e5e5',
    gray91		=> '#e8e8e8',
    gray92		=> '#ebebeb',
    gray93		=> '#ededed',
    gray94		=> '#f0f0f0',
    gray95		=> '#f2f2f2',
    gray96		=> '#f5f5f5',
    gray97		=> '#f7f7f7',
    gray98		=> '#fafafa',
    gray99		=> '#fcfcfc',
    gray100		=> '#ffffff',
    green		=> '#00ff00',
    green1		=> '#00ff00',
    green2		=> '#00ee00',
    green3		=> '#00cd00',
    green4		=> '#008b00',
    greenyellow		=> '#adff2f',
    grey		=> '#c0c0c0',
    grey0		=> '#000000',
    grey1		=> '#030303',
    grey2		=> '#050505',
    grey3		=> '#080808',
    grey4		=> '#0a0a0a',
    grey5		=> '#0d0d0d',
    grey6		=> '#0f0f0f',
    grey7		=> '#121212',
    grey8		=> '#141414',
    grey9		=> '#171717',
    grey10		=> '#1a1a1a',
    grey11		=> '#1c1c1c',
    grey12		=> '#1f1f1f',
    grey13		=> '#212121',
    grey14		=> '#242424',
    grey15		=> '#262626',
    grey16		=> '#292929',
    grey17		=> '#2b2b2b',
    grey18		=> '#2e2e2e',
    grey19		=> '#303030',
    grey20		=> '#333333',
    grey21		=> '#363636',
    grey22		=> '#383838',
    grey23		=> '#3b3b3b',
    grey24		=> '#3d3d3d',
    grey25		=> '#404040',
    grey26		=> '#424242',
    grey27		=> '#454545',
    grey28		=> '#474747',
    grey29		=> '#4a4a4a',
    grey30		=> '#4d4d4d',
    grey31		=> '#4f4f4f',
    grey32		=> '#525252',
    grey33		=> '#545454',
    grey34		=> '#575757',
    grey35		=> '#595959',
    grey36		=> '#5c5c5c',
    grey37		=> '#5e5e5e',
    grey38		=> '#616161',
    grey39		=> '#636363',
    grey40		=> '#666666',
    grey41		=> '#696969',
    grey42		=> '#6b6b6b',
    grey43		=> '#6e6e6e',
    grey44		=> '#707070',
    grey45		=> '#737373',
    grey46		=> '#757575',
    grey47		=> '#787878',
    grey48		=> '#7a7a7a',
    grey49		=> '#7d7d7d',
    grey50		=> '#7f7f7f',
    grey51		=> '#828282',
    grey52		=> '#858585',
    grey53		=> '#878787',
    grey54		=> '#8a8a8a',
    grey55		=> '#8c8c8c',
    grey56		=> '#8f8f8f',
    grey57		=> '#919191',
    grey58		=> '#949494',
    grey59		=> '#969696',
    grey60		=> '#999999',
    grey61		=> '#9c9c9c',
    grey62		=> '#9e9e9e',
    grey63		=> '#a1a1a1',
    grey64		=> '#a3a3a3',
    grey65		=> '#a6a6a6',
    grey66		=> '#a8a8a8',
    grey67		=> '#ababab',
    grey68		=> '#adadad',
    grey69		=> '#b0b0b0',
    grey70		=> '#b3b3b3',
    grey71		=> '#b5b5b5',
    grey72		=> '#b8b8b8',
    grey73		=> '#bababa',
    grey74		=> '#bdbdbd',
    grey75		=> '#bfbfbf',
    grey76		=> '#c2c2c2',
    grey77		=> '#c4c4c4',
    grey78		=> '#c7c7c7',
    grey79		=> '#c9c9c9',
    grey80		=> '#cccccc',
    grey81		=> '#cfcfcf',
    grey82		=> '#d1d1d1',
    grey83		=> '#d4d4d4',
    grey84		=> '#d6d6d6',
    grey85		=> '#d9d9d9',
    grey86		=> '#dbdbdb',
    grey87		=> '#dedede',
    grey88		=> '#e0e0e0',
    grey89		=> '#e3e3e3',
    grey90		=> '#e5e5e5',
    grey91		=> '#e8e8e8',
    grey92		=> '#ebebeb',
    grey93		=> '#ededed',
    grey94		=> '#f0f0f0',
    grey95		=> '#f2f2f2',
    grey96		=> '#f5f5f5',
    grey97		=> '#f7f7f7',
    grey98		=> '#fafafa',
    grey99		=> '#fcfcfc',
    grey100		=> '#ffffff',
    honeydew		=> '#f0fff0',
    honeydew1		=> '#f0fff0',
    honeydew2		=> '#e0eee0',
    honeydew3		=> '#c1cdc1',
    honeydew4		=> '#838b83',
    hotpink		=> '#ff69b4',
    hotpink1		=> '#ff6eb4',
    hotpink2		=> '#ee6aa7',
    hotpink3		=> '#cd6090',
    hotpink4		=> '#8b3a62',
    indianred		=> '#cd5c5c',
    indianred1		=> '#ff6a6a',
    indianred2		=> '#ee6363',
    indianred3		=> '#cd5555',
    indianred4		=> '#8b3a3a',
    indigo		=> '#4b0082',
    ivory		=> '#fffff0',
    ivory1		=> '#fffff0',
    ivory2		=> '#eeeee0',
    ivory3		=> '#cdcdc1',
    ivory4		=> '#8b8b83',
    khaki		=> '#f0e68c',
    khaki1		=> '#fff68f',
    khaki2		=> '#eee685',
    khaki3		=> '#cdc673',
    khaki4		=> '#8b864e',
    lavender		=> '#e6e6fa',
    lavenderblush	=> '#fff0f5',
    lavenderblush1	=> '#fff0f5',
    lavenderblush2	=> '#eee0e5',
    lavenderblush3	=> '#cdc1c5',
    lavenderblush4	=> '#8b8386',
    lawngreen		=> '#7cfc00',
    lemonchiffon	=> '#fffacd',
    lemonchiffon1	=> '#fffacd',
    lemonchiffon2	=> '#eee9bf',
    lemonchiffon3	=> '#cdc9a5',
    lemonchiffon4	=> '#8b8970',
    lightblue		=> '#add8e6',
    lightblue1		=> '#bfefff',
    lightblue2		=> '#b2dfee',
    lightblue3		=> '#9ac0cd',
    lightblue4		=> '#68838b',
    lightcoral		=> '#f08080',
    lightcyan		=> '#e0ffff',
    lightcyan1		=> '#e0ffff',
    lightcyan2		=> '#d1eeee',
    lightcyan3		=> '#b4cdcd',
    lightcyan4		=> '#7a8b8b',
    lightgoldenrod	=> '#eedd82',
    lightgoldenrod1	=> '#ffec8b',
    lightgoldenrod2	=> '#eedc82',
    lightgoldenrod3	=> '#cdbe70',
    lightgoldenrod4	=> '#8b814c',
    lightgoldenrodyellow	=> '#fafad2',
    lightgray		=> '#d3d3d3',
    lightgrey		=> '#d3d3d3',
    lightpink		=> '#ffb6c1',
    lightpink1		=> '#ffaeb9',
    lightpink2		=> '#eea2ad',
    lightpink3		=> '#cd8c95',
    lightpink4		=> '#8b5f65',
    lightsalmon		=> '#ffa07a',
    lightsalmon1	=> '#ffa07a',
    lightsalmon2	=> '#ee9572',
    lightsalmon3	=> '#cd8162',
    lightsalmon4	=> '#8b5742',
    lightseagreen	=> '#20b2aa',
    lightskyblue	=> '#87cefa',
    lightskyblue1	=> '#b0e2ff',
    lightskyblue2	=> '#a4d3ee',
    lightskyblue3	=> '#8db6cd',
    lightskyblue4	=> '#607b8b',
    lightslateblue	=> '#8470ff',
    lightslategray	=> '#778899',
    lightslategrey	=> '#778899',
    lightsteelblue	=> '#b0c4de',
    lightsteelblue1	=> '#cae1ff',
    lightsteelblue2	=> '#bcd2ee',
    lightsteelblue3	=> '#a2b5cd',
    lightsteelblue4	=> '#6e7b8b',
    lightyellow		=> '#ffffe0',
    lightyellow1	=> '#ffffe0',
    lightyellow2	=> '#eeeed1',
    lightyellow3	=> '#cdcdb4',
    lightyellow4	=> '#8b8b7a',
    limegreen		=> '#32cd32',
    linen		=> '#faf0e6',
    magenta		=> '#ff00ff',
    magenta1		=> '#ff00ff',
    magenta2		=> '#ee00ee',
    magenta3		=> '#cd00cd',
    magenta4		=> '#8b008b',
    maroon		=> '#b03060',
    maroon1		=> '#ff34b3',
    maroon2		=> '#ee30a7',
    maroon3		=> '#cd2990',
    maroon4		=> '#8b1c62',
    mediumaquamarine	=> '#66cdaa',
    mediumblue		=> '#0000cd',
    mediumorchid	=> '#ba55d3',
    mediumorchid1	=> '#e066ff',
    mediumorchid2	=> '#d15fee',
    mediumorchid3	=> '#b452cd',
    mediumorchid4	=> '#7a378b',
    mediumpurple	=> '#9370db',
    mediumpurple1	=> '#ab82ff',
    mediumpurple2	=> '#9f79ee',
    mediumpurple3	=> '#8968cd',
    mediumpurple4	=> '#5d478b',
    mediumseagreen	=> '#3cb371',
    mediumslateblue	=> '#7b68ee',
    mediumspringgreen	=> '#00fa9a',
    mediumturquoise	=> '#48d1cc',
    mediumvioletred	=> '#c71585',
    midnightblue	=> '#191970',
    mintcream		=> '#f5fffa',
    mistyrose		=> '#ffe4e1',
    mistyrose1		=> '#ffe4e1',
    mistyrose2		=> '#eed5d2',
    mistyrose3		=> '#cdb7b5',
    mistyrose4		=> '#8b7d7b',
    moccasin		=> '#ffe4b5',
    navajowhite		=> '#ffdead',
    navajowhite1	=> '#ffdead',
    navajowhite2	=> '#eecfa1',
    navajowhite3	=> '#cdb38b',
    navajowhite4	=> '#8b795e',
    navy		=> '#000080',
    navyblue		=> '#000080',
    oldlace		=> '#fdf5e6',
    olivedrab		=> '#6b8e23',
    olivedrab1		=> '#c0ff3e',
    olivedrab2		=> '#b3ee3a',
    olivedrab3		=> '#9acd32',
    olivedrab4		=> '#698b22',
    orange		=> '#ffa500',
    orange1		=> '#ffa500',
    orange2		=> '#ee9a00',
    orange3		=> '#cd8500',
    orange4		=> '#8b5a00',
    orangered		=> '#ff4500',
    orangered1		=> '#ff4500',
    orangered2		=> '#ee4000',
    orangered3		=> '#cd3700',
    orangered4		=> '#8b2500',
    orchid		=> '#da70d6',
    orchid1		=> '#ff83fa',
    orchid2		=> '#ee7ae9',
    orchid3		=> '#cd69c9',
    orchid4		=> '#8b4789',
    palegoldenrod	=> '#eee8aa',
    palegreen		=> '#98fb98',
    palegreen1		=> '#9aff9a',
    palegreen2		=> '#90ee90',
    palegreen3		=> '#7ccd7c',
    palegreen4		=> '#548b54',
    paleturquoise	=> '#afeeee',
    paleturquoise1	=> '#bbffff',
    paleturquoise2	=> '#aeeeee',
    paleturquoise3	=> '#96cdcd',
    paleturquoise4	=> '#668b8b',
    palevioletred	=> '#db7093',
    palevioletred1	=> '#ff82ab',
    palevioletred2	=> '#ee799f',
    palevioletred3	=> '#cd6889',
    palevioletred4	=> '#8b475d',
    papayawhip		=> '#ffefd5',
    peachpuff		=> '#ffdab9',
    peachpuff1		=> '#ffdab9',
    peachpuff2		=> '#eecbad',
    peachpuff3		=> '#cdaf95',
    peachpuff4		=> '#8b7765',
    peru		=> '#cd853f',
    pink		=> '#ffc0cb',
    pink1		=> '#ffb5c5',
    pink2		=> '#eea9b8',
    pink3		=> '#cd919e',
    pink4		=> '#8b636c',
    plum		=> '#dda0dd',
    plum1		=> '#ffbbff',
    plum2		=> '#eeaeee',
    plum3		=> '#cd96cd',
    plum4		=> '#8b668b',
    powderblue		=> '#b0e0e6',
    purple		=> '#a020f0',
    purple1		=> '#9b30ff',
    purple2		=> '#912cee',
    purple3		=> '#7d26cd',
    purple4		=> '#551a8b',
    red 		=> '#ff0000',
    red1		=> '#ff0000',
    red2		=> '#ee0000',
    red3		=> '#cd0000',
    red4		=> '#8b0000',
    rosybrown		=> '#bc8f8f',
    rosybrown1		=> '#ffc1c1',
    rosybrown2		=> '#eeb4b4',
    rosybrown3		=> '#cd9b9b',
    rosybrown4		=> '#8b6969',
    royalblue		=> '#4169e1',
    royalblue1		=> '#4876ff',
    royalblue2		=> '#436eee',
    royalblue3		=> '#3a5fcd',
    royalblue4		=> '#27408b',
    saddlebrown		=> '#8b4513',
    salmon		=> '#fa8072',
    salmon1		=> '#ff8c69',
    salmon2		=> '#ee8262',
    salmon3		=> '#cd7054',
    salmon4		=> '#8b4c39',
    sandybrown		=> '#f4a460',
    seagreen		=> '#2e8b57',
    seagreen1		=> '#54ff9f',
    seagreen2		=> '#4eee94',
    seagreen3		=> '#43cd80',
    seagreen4		=> '#2e8b57',
    seashell		=> '#fff5ee',
    seashell1		=> '#fff5ee',
    seashell2		=> '#eee5de',
    seashell3		=> '#cdc5bf',
    seashell4		=> '#8b8682',
    sienna		=> '#a0522d',
    sienna1		=> '#ff8247',
    sienna2		=> '#ee7942',
    sienna3		=> '#cd6839',
    sienna4		=> '#8b4726',
    skyblue		=> '#87ceeb',
    skyblue1		=> '#87ceff',
    skyblue2		=> '#7ec0ee',
    skyblue3		=> '#6ca6cd',
    skyblue4		=> '#4a708b',
    slateblue		=> '#6a5acd',
    slateblue1		=> '#836fff',
    slateblue2		=> '#7a67ee',
    slateblue3		=> '#6959cd',
    slateblue4		=> '#473c8b',
    slategray		=> '#708090',
    slategray1		=> '#c6e2ff',
    slategray2		=> '#b9d3ee',
    slategray3		=> '#9fb6cd',
    slategray4		=> '#6c7b8b',
    slategrey		=> '#708090',
    snow		=> '#fffafa',
    snow1		=> '#fffafa',
    snow2		=> '#eee9e9',
    snow3		=> '#cdc9c9',
    snow4		=> '#8b8989',
    springgreen		=> '#00ff7f',
    springgreen1	=> '#00ff7f',
    springgreen2	=> '#00ee76',
    springgreen3	=> '#00cd66',
    springgreen4	=> '#008b45',
    steelblue		=> '#4682b4',
    steelblue1		=> '#63b8ff',
    steelblue2		=> '#5cacee',
    steelblue3		=> '#4f94cd',
    steelblue4		=> '#36648b',
    tan 		=> '#d2b48c',
    tan1		=> '#ffa54f',
    tan2		=> '#ee9a49',
    tan3		=> '#cd853f',
    tan4		=> '#8b5a2b',
    thistle		=> '#d8bfd8',
    thistle1		=> '#ffe1ff',
    thistle2		=> '#eed2ee',
    thistle3		=> '#cdb5cd',
    thistle4		=> '#8b7b8b',
    tomato		=> '#ff6347',
    tomato1		=> '#ff6347',
    tomato2		=> '#ee5c42',
    tomato3		=> '#cd4f39',
    tomato4		=> '#8b3626',
    transparent		=> '#fffffe',
    turquoise		=> '#40e0d0',
    turquoise1		=> '#00f5ff',
    turquoise2		=> '#00e5ee',
    turquoise3		=> '#00c5cd',
    turquoise4		=> '#00868b',
    violet		=> '#ee82ee',
    violetred		=> '#d02090',
    violetred1		=> '#ff3e96',
    violetred2		=> '#ee3a8c',
    violetred3		=> '#cd3278',
    violetred4		=> '#8b2252',
    wheat		=> '#f5deb3',
    wheat1		=> '#ffe7ba',
    wheat2		=> '#eed8ae',
    wheat3		=> '#cdba96',
    wheat4		=> '#8b7e66',
    white		=> '#ffffff',
    whitesmoke		=> '#f5f5f5',
    yellow		=> '#ffff00',
    yellow1		=> '#ffff00',
    yellow2		=> '#eeee00',
    yellow3		=> '#cdcd00',
    yellow4		=> '#8b8b00',
    yellowgreen		=> '#9acd32',
    # The following 12 colors exist here so that a "color: 3; colorscheme: accent3"
    # will not report an "unknown color 3" from the Parser. As a side-effect
    # you will not get an error for a plain "color: 3".
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 4  => '#33a02c', 
    5  => '#fb9a99', 6  => '#e31a1c', 7  => '#fdbf6f', 8  => '#ff7f00', 
    9  => '#cab2d6', 10  => '#6a3d9a', 11  => '#ffff99', 12  => '#b15928', 
  },
# The following color specifications were developed by:
#  Cynthia Brewer (http://colorbrewer.org/)
# See the LICENSE FILE for the full license that applies to them.

  accent3 => {
    1  => '#7fc97f', 2  => '#beaed4', 3  => '#fdc086', 
  },
  accent4 => {
    1  => '#7fc97f', 2  => '#beaed4', 3  => '#fdc086', 4  => '#ffff99', 
  },
  accent5 => {
    1  => '#7fc97f', 2  => '#beaed4', 3  => '#fdc086', 4  => '#ffff99', 
    5  => '#386cb0', 
  },
  accent6 => {
    1  => '#7fc97f', 2  => '#beaed4', 3  => '#fdc086', 4  => '#ffff99', 
    5  => '#386cb0', 6  => '#f0027f', 
  },
  accent7 => {
    1  => '#7fc97f', 2  => '#beaed4', 3  => '#fdc086', 4  => '#ffff99', 
    5  => '#386cb0', 6  => '#f0027f', 7  => '#bf5b17', 
  },
  accent8 => {
    1  => '#7fc97f', 2  => '#beaed4', 3  => '#fdc086', 4  => '#ffff99', 
    5  => '#386cb0', 6  => '#f0027f', 7  => '#bf5b17', 8  => '#666666', 
  },
  blues3 => {
    1  => '#deebf7', 2  => '#9ecae1', 3  => '#3182bd', 
  },
  blues4 => {
    1  => '#eff3ff', 2  => '#bdd7e7', 3  => '#6baed6', 4  => '#2171b5', 
  },
  blues5 => {
    1  => '#eff3ff', 2  => '#bdd7e7', 3  => '#6baed6', 4  => '#3182bd', 
    5  => '#08519c', 
  },
  blues6 => {
    1  => '#eff3ff', 2  => '#c6dbef', 3  => '#9ecae1', 4  => '#6baed6', 
    5  => '#3182bd', 6  => '#08519c', 
  },
  blues7 => {
    1  => '#eff3ff', 2  => '#c6dbef', 3  => '#9ecae1', 4  => '#6baed6', 
    5  => '#4292c6', 6  => '#2171b5', 7  => '#084594', 
  },
  blues8 => {
    1  => '#f7fbff', 2  => '#deebf7', 3  => '#c6dbef', 4  => '#9ecae1', 
    5  => '#6baed6', 6  => '#4292c6', 7  => '#2171b5', 8  => '#084594', 
  },
  blues9 => {
    1  => '#f7fbff', 2  => '#deebf7', 3  => '#c6dbef', 4  => '#9ecae1', 
    5  => '#6baed6', 6  => '#4292c6', 7  => '#2171b5', 8  => '#08519c', 
    9  => '#08306b', 
  },
  brbg3 => {
    1  => '#d8b365', 2  => '#f5f5f5', 3  => '#5ab4ac', 
  },
  brbg4 => {
    1  => '#a6611a', 2  => '#dfc27d', 3  => '#80cdc1', 4  => '#018571', 
  },
  brbg5 => {
    1  => '#a6611a', 2  => '#dfc27d', 3  => '#f5f5f5', 4  => '#80cdc1', 
    5  => '#018571', 
  },
  brbg6 => {
    1  => '#8c510a', 2  => '#d8b365', 3  => '#f6e8c3', 4  => '#c7eae5', 
    5  => '#5ab4ac', 6  => '#01665e', 
  },
  brbg7 => {
    1  => '#8c510a', 2  => '#d8b365', 3  => '#f6e8c3', 4  => '#f5f5f5', 
    5  => '#c7eae5', 6  => '#5ab4ac', 7  => '#01665e', 
  },
  brbg8 => {
    1  => '#8c510a', 2  => '#bf812d', 3  => '#dfc27d', 4  => '#f6e8c3', 
    5  => '#c7eae5', 6  => '#80cdc1', 7  => '#35978f', 8  => '#01665e', 
  },
  brbg9 => {
    1  => '#8c510a', 2  => '#bf812d', 3  => '#dfc27d', 4  => '#f6e8c3', 
    5  => '#f5f5f5', 6  => '#c7eae5', 7  => '#80cdc1', 8  => '#35978f', 
    9  => '#01665e', 
  },
  brbg10 => {
    1  => '#543005', 2  => '#8c510a', 3  => '#bf812d', 4  => '#dfc27d', 
    5  => '#f6e8c3', 6  => '#c7eae5', 7  => '#80cdc1', 8  => '#35978f', 
    9  => '#01665e', 10  => '#003c30', 
  },
  brbg11 => {
    1  => '#543005', 2  => '#8c510a', 3  => '#bf812d', 4  => '#dfc27d', 
    5  => '#f6e8c3', 6  => '#f5f5f5', 7  => '#c7eae5', 8  => '#80cdc1', 
    9  => '#35978f', 10  => '#01665e', 11  => '#003c30', 
  },
  bugn3 => {
    1  => '#e5f5f9', 2  => '#99d8c9', 3  => '#2ca25f', 
  },
  bugn4 => {
    1  => '#edf8fb', 2  => '#b2e2e2', 3  => '#66c2a4', 4  => '#238b45', 
  },
  bugn5 => {
    1  => '#edf8fb', 2  => '#b2e2e2', 3  => '#66c2a4', 4  => '#2ca25f', 
    5  => '#006d2c', 
  },
  bugn6 => {
    1  => '#edf8fb', 2  => '#ccece6', 3  => '#99d8c9', 4  => '#66c2a4', 
    5  => '#2ca25f', 6  => '#006d2c', 
  },
  bugn7 => {
    1  => '#edf8fb', 2  => '#ccece6', 3  => '#99d8c9', 4  => '#66c2a4', 
    5  => '#41ae76', 6  => '#238b45', 7  => '#005824', 
  },
  bugn8 => {
    1  => '#f7fcfd', 2  => '#e5f5f9', 3  => '#ccece6', 4  => '#99d8c9', 
    5  => '#66c2a4', 6  => '#41ae76', 7  => '#238b45', 8  => '#005824', 
  },
  bugn9 => {
    1  => '#f7fcfd', 2  => '#e5f5f9', 3  => '#ccece6', 4  => '#99d8c9', 
    5  => '#66c2a4', 6  => '#41ae76', 7  => '#238b45', 8  => '#006d2c', 
    9  => '#00441b', 
  },
  bupu3 => {
    1  => '#e0ecf4', 2  => '#9ebcda', 3  => '#8856a7', 
  },
  bupu4 => {
    1  => '#edf8fb', 2  => '#b3cde3', 3  => '#8c96c6', 4  => '#88419d', 
  },
  bupu5 => {
    1  => '#edf8fb', 2  => '#b3cde3', 3  => '#8c96c6', 4  => '#8856a7', 
    5  => '#810f7c', 
  },
  bupu6 => {
    1  => '#edf8fb', 2  => '#bfd3e6', 3  => '#9ebcda', 4  => '#8c96c6', 
    5  => '#8856a7', 6  => '#810f7c', 
  },
  bupu7 => {
    1  => '#edf8fb', 2  => '#bfd3e6', 3  => '#9ebcda', 4  => '#8c96c6', 
    5  => '#8c6bb1', 6  => '#88419d', 7  => '#6e016b', 
  },
  bupu8 => {
    1  => '#f7fcfd', 2  => '#e0ecf4', 3  => '#bfd3e6', 4  => '#9ebcda', 
    5  => '#8c96c6', 6  => '#8c6bb1', 7  => '#88419d', 8  => '#6e016b', 
  },
  bupu9 => {
    1  => '#f7fcfd', 2  => '#e0ecf4', 3  => '#bfd3e6', 4  => '#9ebcda', 
    5  => '#8c96c6', 6  => '#8c6bb1', 7  => '#88419d', 8  => '#810f7c', 
    9  => '#4d004b', 
  },
  dark23 => {
    1  => '#1b9e77', 2  => '#d95f02', 3  => '#7570b3', 
  },
  dark24 => {
    1  => '#1b9e77', 2  => '#d95f02', 3  => '#7570b3', 4  => '#e7298a', 
  },
  dark25 => {
    1  => '#1b9e77', 2  => '#d95f02', 3  => '#7570b3', 4  => '#e7298a', 
    5  => '#66a61e', 
  },
  dark26 => {
    1  => '#1b9e77', 2  => '#d95f02', 3  => '#7570b3', 4  => '#e7298a', 
    5  => '#66a61e', 6  => '#e6ab02', 
  },
  dark27 => {
    1  => '#1b9e77', 2  => '#d95f02', 3  => '#7570b3', 4  => '#e7298a', 
    5  => '#66a61e', 6  => '#e6ab02', 7  => '#a6761d', 
  },
  dark28 => {
    1  => '#1b9e77', 2  => '#d95f02', 3  => '#7570b3', 4  => '#e7298a', 
    5  => '#66a61e', 6  => '#e6ab02', 7  => '#a6761d', 8  => '#666666', 
  },
  gnbu3 => {
    1  => '#e0f3db', 2  => '#a8ddb5', 3  => '#43a2ca', 
  },
  gnbu4 => {
    1  => '#f0f9e8', 2  => '#bae4bc', 3  => '#7bccc4', 4  => '#2b8cbe', 
  },
  gnbu5 => {
    1  => '#f0f9e8', 2  => '#bae4bc', 3  => '#7bccc4', 4  => '#43a2ca', 
    5  => '#0868ac', 
  },
  gnbu6 => {
    1  => '#f0f9e8', 2  => '#ccebc5', 3  => '#a8ddb5', 4  => '#7bccc4', 
    5  => '#43a2ca', 6  => '#0868ac', 
  },
  gnbu7 => {
    1  => '#f0f9e8', 2  => '#ccebc5', 3  => '#a8ddb5', 4  => '#7bccc4', 
    5  => '#4eb3d3', 6  => '#2b8cbe', 7  => '#08589e', 
  },
  gnbu8 => {
    1  => '#f7fcf0', 2  => '#e0f3db', 3  => '#ccebc5', 4  => '#a8ddb5', 
    5  => '#7bccc4', 6  => '#4eb3d3', 7  => '#2b8cbe', 8  => '#08589e', 
  },
  gnbu9 => {
    1  => '#f7fcf0', 2  => '#e0f3db', 3  => '#ccebc5', 4  => '#a8ddb5', 
    5  => '#7bccc4', 6  => '#4eb3d3', 7  => '#2b8cbe', 8  => '#0868ac', 
    9  => '#084081', 
  },
  greens3 => {
    1  => '#e5f5e0', 2  => '#a1d99b', 3  => '#31a354', 
  },
  greens4 => {
    1  => '#edf8e9', 2  => '#bae4b3', 3  => '#74c476', 4  => '#238b45', 
  },
  greens5 => {
    1  => '#edf8e9', 2  => '#bae4b3', 3  => '#74c476', 4  => '#31a354', 
    5  => '#006d2c', 
  },
  greens6 => {
    1  => '#edf8e9', 2  => '#c7e9c0', 3  => '#a1d99b', 4  => '#74c476', 
    5  => '#31a354', 6  => '#006d2c', 
  },
  greens7 => {
    1  => '#edf8e9', 2  => '#c7e9c0', 3  => '#a1d99b', 4  => '#74c476', 
    5  => '#41ab5d', 6  => '#238b45', 7  => '#005a32', 
  },
  greens8 => {
    1  => '#f7fcf5', 2  => '#e5f5e0', 3  => '#c7e9c0', 4  => '#a1d99b', 
    5  => '#74c476', 6  => '#41ab5d', 7  => '#238b45', 8  => '#005a32', 
  },
  greens9 => {
    1  => '#f7fcf5', 2  => '#e5f5e0', 3  => '#c7e9c0', 4  => '#a1d99b', 
    5  => '#74c476', 6  => '#41ab5d', 7  => '#238b45', 8  => '#006d2c', 
    9  => '#00441b', 
  },
  greys3 => {
    1  => '#f0f0f0', 2  => '#bdbdbd', 3  => '#636363', 
  },
  greys4 => {
    1  => '#f7f7f7', 2  => '#cccccc', 3  => '#969696', 4  => '#525252', 
  },
  greys5 => {
    1  => '#f7f7f7', 2  => '#cccccc', 3  => '#969696', 4  => '#636363', 
    5  => '#252525', 
  },
  greys6 => {
    1  => '#f7f7f7', 2  => '#d9d9d9', 3  => '#bdbdbd', 4  => '#969696', 
    5  => '#636363', 6  => '#252525', 
  },
  greys7 => {
    1  => '#f7f7f7', 2  => '#d9d9d9', 3  => '#bdbdbd', 4  => '#969696', 
    5  => '#737373', 6  => '#525252', 7  => '#252525', 
  },
  greys8 => {
    1  => '#ffffff', 2  => '#f0f0f0', 3  => '#d9d9d9', 4  => '#bdbdbd', 
    5  => '#969696', 6  => '#737373', 7  => '#525252', 8  => '#252525', 
  },
  greys9 => {
    1  => '#ffffff', 2  => '#f0f0f0', 3  => '#d9d9d9', 4  => '#bdbdbd', 
    5  => '#969696', 6  => '#737373', 7  => '#525252', 8  => '#252525', 
    9  => '#000000', 
  },
  oranges3 => {
    1  => '#fee6ce', 2  => '#fdae6b', 3  => '#e6550d', 
  },
  oranges4 => {
    1  => '#feedde', 2  => '#fdbe85', 3  => '#fd8d3c', 4  => '#d94701', 
  },
  oranges5 => {
    1  => '#feedde', 2  => '#fdbe85', 3  => '#fd8d3c', 4  => '#e6550d', 
    5  => '#a63603', 
  },
  oranges6 => {
    1  => '#feedde', 2  => '#fdd0a2', 3  => '#fdae6b', 4  => '#fd8d3c', 
    5  => '#e6550d', 6  => '#a63603', 
  },
  oranges7 => {
    1  => '#feedde', 2  => '#fdd0a2', 3  => '#fdae6b', 4  => '#fd8d3c', 
    5  => '#f16913', 6  => '#d94801', 7  => '#8c2d04', 
  },
  oranges8 => {
    1  => '#fff5eb', 2  => '#fee6ce', 3  => '#fdd0a2', 4  => '#fdae6b', 
    5  => '#fd8d3c', 6  => '#f16913', 7  => '#d94801', 8  => '#8c2d04', 
  },
  oranges9 => {
    1  => '#fff5eb', 2  => '#fee6ce', 3  => '#fdd0a2', 4  => '#fdae6b', 
    5  => '#fd8d3c', 6  => '#f16913', 7  => '#d94801', 8  => '#a63603', 
    9  => '#7f2704', 
  },
  orrd3 => {
    1  => '#fee8c8', 2  => '#fdbb84', 3  => '#e34a33', 
  },
  orrd4 => {
    1  => '#fef0d9', 2  => '#fdcc8a', 3  => '#fc8d59', 4  => '#d7301f', 
  },
  orrd5 => {
    1  => '#fef0d9', 2  => '#fdcc8a', 3  => '#fc8d59', 4  => '#e34a33', 
    5  => '#b30000', 
  },
  orrd6 => {
    1  => '#fef0d9', 2  => '#fdd49e', 3  => '#fdbb84', 4  => '#fc8d59', 
    5  => '#e34a33', 6  => '#b30000', 
  },
  orrd7 => {
    1  => '#fef0d9', 2  => '#fdd49e', 3  => '#fdbb84', 4  => '#fc8d59', 
    5  => '#ef6548', 6  => '#d7301f', 7  => '#990000', 
  },
  orrd8 => {
    1  => '#fff7ec', 2  => '#fee8c8', 3  => '#fdd49e', 4  => '#fdbb84', 
    5  => '#fc8d59', 6  => '#ef6548', 7  => '#d7301f', 8  => '#990000', 
  },
  orrd9 => {
    1  => '#fff7ec', 2  => '#fee8c8', 3  => '#fdd49e', 4  => '#fdbb84', 
    5  => '#fc8d59', 6  => '#ef6548', 7  => '#d7301f', 8  => '#b30000', 
    9  => '#7f0000', 
  },
  paired3 => {
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 
  },
  paired4 => {
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 4  => '#33a02c', 
  },
  paired5 => {
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 4  => '#33a02c', 
    5  => '#fb9a99', 
  },
  paired6 => {
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 4  => '#33a02c', 
    5  => '#fb9a99', 6  => '#e31a1c', 
  },
  paired7 => {
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 4  => '#33a02c', 
    5  => '#fb9a99', 6  => '#e31a1c', 7  => '#fdbf6f', 
  },
  paired8 => {
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 4  => '#33a02c', 
    5  => '#fb9a99', 6  => '#e31a1c', 7  => '#fdbf6f', 8  => '#ff7f00', 
  },
  paired9 => {
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 4  => '#33a02c', 
    5  => '#fb9a99', 6  => '#e31a1c', 7  => '#fdbf6f', 8  => '#ff7f00', 
    9  => '#cab2d6', 
  },
  paired10 => {
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 4  => '#33a02c', 
    5  => '#fb9a99', 6  => '#e31a1c', 7  => '#fdbf6f', 8  => '#ff7f00', 
    9  => '#cab2d6', 10  => '#6a3d9a', 
  },
  paired11 => {
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 4  => '#33a02c', 
    5  => '#fb9a99', 6  => '#e31a1c', 7  => '#fdbf6f', 8  => '#ff7f00', 
    9  => '#cab2d6', 10  => '#6a3d9a', 11  => '#ffff99', 
  },
  paired12 => {
    1  => '#a6cee3', 2  => '#1f78b4', 3  => '#b2df8a', 4  => '#33a02c', 
    5  => '#fb9a99', 6  => '#e31a1c', 7  => '#fdbf6f', 8  => '#ff7f00', 
    9  => '#cab2d6', 10  => '#6a3d9a', 11  => '#ffff99', 12  => '#b15928', 
  },
  pastel13 => {
    1  => '#fbb4ae', 2  => '#b3cde3', 3  => '#ccebc5', 
  },
  pastel14 => {
    1  => '#fbb4ae', 2  => '#b3cde3', 3  => '#ccebc5', 4  => '#decbe4', 
  },
  pastel15 => {
    1  => '#fbb4ae', 2  => '#b3cde3', 3  => '#ccebc5', 4  => '#decbe4', 
    5  => '#fed9a6', 
  },
  pastel16 => {
    1  => '#fbb4ae', 2  => '#b3cde3', 3  => '#ccebc5', 4  => '#decbe4', 
    5  => '#fed9a6', 6  => '#ffffcc', 
  },
  pastel17 => {
    1  => '#fbb4ae', 2  => '#b3cde3', 3  => '#ccebc5', 4  => '#decbe4', 
    5  => '#fed9a6', 6  => '#ffffcc', 7  => '#e5d8bd', 
  },
  pastel18 => {
    1  => '#fbb4ae', 2  => '#b3cde3', 3  => '#ccebc5', 4  => '#decbe4', 
    5  => '#fed9a6', 6  => '#ffffcc', 7  => '#e5d8bd', 8  => '#fddaec', 
  },
  pastel19 => {
    1  => '#fbb4ae', 2  => '#b3cde3', 3  => '#ccebc5', 4  => '#decbe4', 
    5  => '#fed9a6', 6  => '#ffffcc', 7  => '#e5d8bd', 8  => '#fddaec', 
    9  => '#f2f2f2', 
  },
  pastel23 => {
    1  => '#b3e2cd', 2  => '#fdcdac', 3  => '#cbd5e8', 
  },
  pastel24 => {
    1  => '#b3e2cd', 2  => '#fdcdac', 3  => '#cbd5e8', 4  => '#f4cae4', 
  },
  pastel25 => {
    1  => '#b3e2cd', 2  => '#fdcdac', 3  => '#cbd5e8', 4  => '#f4cae4', 
    5  => '#e6f5c9', 
  },
  pastel26 => {
    1  => '#b3e2cd', 2  => '#fdcdac', 3  => '#cbd5e8', 4  => '#f4cae4', 
    5  => '#e6f5c9', 6  => '#fff2ae', 
  },
  pastel27 => {
    1  => '#b3e2cd', 2  => '#fdcdac', 3  => '#cbd5e8', 4  => '#f4cae4', 
    5  => '#e6f5c9', 6  => '#fff2ae', 7  => '#f1e2cc', 
  },
  pastel28 => {
    1  => '#b3e2cd', 2  => '#fdcdac', 3  => '#cbd5e8', 4  => '#f4cae4', 
    5  => '#e6f5c9', 6  => '#fff2ae', 7  => '#f1e2cc', 8  => '#cccccc', 
  },
  piyg3 => {
    1  => '#e9a3c9', 2  => '#f7f7f7', 3  => '#a1d76a', 
  },
  piyg4 => {
    1  => '#d01c8b', 2  => '#f1b6da', 3  => '#b8e186', 4  => '#4dac26', 
  },
  piyg5 => {
    1  => '#d01c8b', 2  => '#f1b6da', 3  => '#f7f7f7', 4  => '#b8e186', 
    5  => '#4dac26', 
  },
  piyg6 => {
    1  => '#c51b7d', 2  => '#e9a3c9', 3  => '#fde0ef', 4  => '#e6f5d0', 
    5  => '#a1d76a', 6  => '#4d9221', 
  },
  piyg7 => {
    1  => '#c51b7d', 2  => '#e9a3c9', 3  => '#fde0ef', 4  => '#f7f7f7', 
    5  => '#e6f5d0', 6  => '#a1d76a', 7  => '#4d9221', 
  },
  piyg8 => {
    1  => '#c51b7d', 2  => '#de77ae', 3  => '#f1b6da', 4  => '#fde0ef', 
    5  => '#e6f5d0', 6  => '#b8e186', 7  => '#7fbc41', 8  => '#4d9221', 
  },
  piyg9 => {
    1  => '#c51b7d', 2  => '#de77ae', 3  => '#f1b6da', 4  => '#fde0ef', 
    5  => '#f7f7f7', 6  => '#e6f5d0', 7  => '#b8e186', 8  => '#7fbc41', 
    9  => '#4d9221', 
  },
  piyg10 => {
    1  => '#8e0152', 2  => '#c51b7d', 3  => '#de77ae', 4  => '#f1b6da', 
    5  => '#fde0ef', 6  => '#e6f5d0', 7  => '#b8e186', 8  => '#7fbc41', 
    9  => '#4d9221', 10  => '#276419', 
  },
  piyg11 => {
    1  => '#8e0152', 2  => '#c51b7d', 3  => '#de77ae', 4  => '#f1b6da', 
    5  => '#fde0ef', 6  => '#f7f7f7', 7  => '#e6f5d0', 8  => '#b8e186', 
    9  => '#7fbc41', 10  => '#4d9221', 11  => '#276419', 
  },
  prgn3 => {
    1  => '#af8dc3', 2  => '#f7f7f7', 3  => '#7fbf7b', 
  },
  prgn4 => {
    1  => '#7b3294', 2  => '#c2a5cf', 3  => '#a6dba0', 4  => '#008837', 
  },
  prgn5 => {
    1  => '#7b3294', 2  => '#c2a5cf', 3  => '#f7f7f7', 4  => '#a6dba0', 
    5  => '#008837', 
  },
  prgn6 => {
    1  => '#762a83', 2  => '#af8dc3', 3  => '#e7d4e8', 4  => '#d9f0d3', 
    5  => '#7fbf7b', 6  => '#1b7837', 
  },
  prgn7 => {
    1  => '#762a83', 2  => '#af8dc3', 3  => '#e7d4e8', 4  => '#f7f7f7', 
    5  => '#d9f0d3', 6  => '#7fbf7b', 7  => '#1b7837', 
  },
  prgn8 => {
    1  => '#762a83', 2  => '#9970ab', 3  => '#c2a5cf', 4  => '#e7d4e8', 
    5  => '#d9f0d3', 6  => '#a6dba0', 7  => '#5aae61', 8  => '#1b7837', 
  },
  prgn9 => {
    1  => '#762a83', 2  => '#9970ab', 3  => '#c2a5cf', 4  => '#e7d4e8', 
    5  => '#f7f7f7', 6  => '#d9f0d3', 7  => '#a6dba0', 8  => '#5aae61', 
    9  => '#1b7837', 
  },
  prgn10 => {
    1  => '#40004b', 2  => '#762a83', 3  => '#9970ab', 4  => '#c2a5cf', 
    5  => '#e7d4e8', 6  => '#d9f0d3', 7  => '#a6dba0', 8  => '#5aae61', 
    9  => '#1b7837', 10  => '#00441b', 
  },
  prgn11 => {
    1  => '#40004b', 2  => '#762a83', 3  => '#9970ab', 4  => '#c2a5cf', 
    5  => '#e7d4e8', 6  => '#f7f7f7', 7  => '#d9f0d3', 8  => '#a6dba0', 
    9  => '#5aae61', 10  => '#1b7837', 11  => '#00441b', 
  },
  pubu3 => {
    1  => '#ece7f2', 2  => '#a6bddb', 3  => '#2b8cbe', 
  },
  pubu4 => {
    1  => '#f1eef6', 2  => '#bdc9e1', 3  => '#74a9cf', 4  => '#0570b0', 
  },
  pubu5 => {
    1  => '#f1eef6', 2  => '#bdc9e1', 3  => '#74a9cf', 4  => '#2b8cbe', 
    5  => '#045a8d', 
  },
  pubu6 => {
    1  => '#f1eef6', 2  => '#d0d1e6', 3  => '#a6bddb', 4  => '#74a9cf', 
    5  => '#2b8cbe', 6  => '#045a8d', 
  },
  pubu7 => {
    1  => '#f1eef6', 2  => '#d0d1e6', 3  => '#a6bddb', 4  => '#74a9cf', 
    5  => '#3690c0', 6  => '#0570b0', 7  => '#034e7b', 
  },
  pubu8 => {
    1  => '#fff7fb', 2  => '#ece7f2', 3  => '#d0d1e6', 4  => '#a6bddb', 
    5  => '#74a9cf', 6  => '#3690c0', 7  => '#0570b0', 8  => '#034e7b', 
  },
  pubu9 => {
    1  => '#fff7fb', 2  => '#ece7f2', 3  => '#d0d1e6', 4  => '#a6bddb', 
    5  => '#74a9cf', 6  => '#3690c0', 7  => '#0570b0', 8  => '#045a8d', 
    9  => '#023858', 
  },
  pubugn3 => {
    1  => '#ece2f0', 2  => '#a6bddb', 3  => '#1c9099', 
  },
  pubugn4 => {
    1  => '#f6eff7', 2  => '#bdc9e1', 3  => '#67a9cf', 4  => '#02818a', 
  },
  pubugn5 => {
    1  => '#f6eff7', 2  => '#bdc9e1', 3  => '#67a9cf', 4  => '#1c9099', 
    5  => '#016c59', 
  },
  pubugn6 => {
    1  => '#f6eff7', 2  => '#d0d1e6', 3  => '#a6bddb', 4  => '#67a9cf', 
    5  => '#1c9099', 6  => '#016c59', 
  },
  pubugn7 => {
    1  => '#f6eff7', 2  => '#d0d1e6', 3  => '#a6bddb', 4  => '#67a9cf', 
    5  => '#3690c0', 6  => '#02818a', 7  => '#016450', 
  },
  pubugn8 => {
    1  => '#fff7fb', 2  => '#ece2f0', 3  => '#d0d1e6', 4  => '#a6bddb', 
    5  => '#67a9cf', 6  => '#3690c0', 7  => '#02818a', 8  => '#016450', 
  },
  pubugn9 => {
    1  => '#fff7fb', 2  => '#ece2f0', 3  => '#d0d1e6', 4  => '#a6bddb', 
    5  => '#67a9cf', 6  => '#3690c0', 7  => '#02818a', 8  => '#016c59', 
    9  => '#014636', 
  },
  puor3 => {
    1  => '#f1a340', 2  => '#f7f7f7', 3  => '#998ec3', 
  },
  puor4 => {
    1  => '#e66101', 2  => '#fdb863', 3  => '#b2abd2', 4  => '#5e3c99', 
  },
  puor5 => {
    1  => '#e66101', 2  => '#fdb863', 3  => '#f7f7f7', 4  => '#b2abd2', 
    5  => '#5e3c99', 
  },
  puor6 => {
    1  => '#b35806', 2  => '#f1a340', 3  => '#fee0b6', 4  => '#d8daeb', 
    5  => '#998ec3', 6  => '#542788', 
  },
  puor7 => {
    1  => '#b35806', 2  => '#f1a340', 3  => '#fee0b6', 4  => '#f7f7f7', 
    5  => '#d8daeb', 6  => '#998ec3', 7  => '#542788', 
  },
  puor8 => {
    1  => '#b35806', 2  => '#e08214', 3  => '#fdb863', 4  => '#fee0b6', 
    5  => '#d8daeb', 6  => '#b2abd2', 7  => '#8073ac', 8  => '#542788', 
  },
  puor9 => {
    1  => '#b35806', 2  => '#e08214', 3  => '#fdb863', 4  => '#fee0b6', 
    5  => '#f7f7f7', 6  => '#d8daeb', 7  => '#b2abd2', 8  => '#8073ac', 
    9  => '#542788', 
  },
  purd3 => {
    1  => '#e7e1ef', 2  => '#c994c7', 3  => '#dd1c77', 
  },
  purd4 => {
    1  => '#f1eef6', 2  => '#d7b5d8', 3  => '#df65b0', 4  => '#ce1256', 
  },
  purd5 => {
    1  => '#f1eef6', 2  => '#d7b5d8', 3  => '#df65b0', 4  => '#dd1c77', 
    5  => '#980043', 
  },
  purd6 => {
    1  => '#f1eef6', 2  => '#d4b9da', 3  => '#c994c7', 4  => '#df65b0', 
    5  => '#dd1c77', 6  => '#980043', 
  },
  purd7 => {
    1  => '#f1eef6', 2  => '#d4b9da', 3  => '#c994c7', 4  => '#df65b0', 
    5  => '#e7298a', 6  => '#ce1256', 7  => '#91003f', 
  },
  purd8 => {
    1  => '#f7f4f9', 2  => '#e7e1ef', 3  => '#d4b9da', 4  => '#c994c7', 
    5  => '#df65b0', 6  => '#e7298a', 7  => '#ce1256', 8  => '#91003f', 
  },
  purd9 => {
    1  => '#f7f4f9', 2  => '#e7e1ef', 3  => '#d4b9da', 4  => '#c994c7', 
    5  => '#df65b0', 6  => '#e7298a', 7  => '#ce1256', 8  => '#980043', 
    9  => '#67001f', 
  },
  puor10 => {
    1  => '#7f3b08', 2  => '#b35806', 3  => '#e08214', 4  => '#fdb863', 
    5  => '#fee0b6', 6  => '#d8daeb', 7  => '#b2abd2', 8  => '#8073ac', 
    9  => '#542788', 10  => '#2d004b', 
  },
  puor11 => {
    1  => '#7f3b08', 2  => '#b35806', 3  => '#e08214', 4  => '#fdb863', 
    5  => '#fee0b6', 6  => '#f7f7f7', 7  => '#d8daeb', 8  => '#b2abd2', 
    9  => '#8073ac', 10  => '#542788', 11  => '#2d004b', 
  },
  purples3 => {
    1  => '#efedf5', 2  => '#bcbddc', 3  => '#756bb1', 
  },
  purples4 => {
    1  => '#f2f0f7', 2  => '#cbc9e2', 3  => '#9e9ac8', 4  => '#6a51a3', 
  },
  purples5 => {
    1  => '#f2f0f7', 2  => '#cbc9e2', 3  => '#9e9ac8', 4  => '#756bb1', 
    5  => '#54278f', 
  },
  purples6 => {
    1  => '#f2f0f7', 2  => '#dadaeb', 3  => '#bcbddc', 4  => '#9e9ac8', 
    5  => '#756bb1', 6  => '#54278f', 
  },
  purples7 => {
    1  => '#f2f0f7', 2  => '#dadaeb', 3  => '#bcbddc', 4  => '#9e9ac8', 
    5  => '#807dba', 6  => '#6a51a3', 7  => '#4a1486', 
  },
  purples8 => {
    1  => '#fcfbfd', 2  => '#efedf5', 3  => '#dadaeb', 4  => '#bcbddc', 
    5  => '#9e9ac8', 6  => '#807dba', 7  => '#6a51a3', 8  => '#4a1486', 
  },
  purples9 => {
    1  => '#fcfbfd', 2  => '#efedf5', 3  => '#dadaeb', 4  => '#bcbddc', 
    5  => '#9e9ac8', 6  => '#807dba', 7  => '#6a51a3', 8  => '#54278f', 
    9  => '#3f007d', 
  },
  rdbu10 => {
    1  => '#67001f', 2  => '#b2182b', 3  => '#d6604d', 4  => '#f4a582', 
    5  => '#fddbc7', 6  => '#d1e5f0', 7  => '#92c5de', 8  => '#4393c3', 
    9  => '#2166ac', 10  => '#053061', 
  },
  rdbu11 => {
    1  => '#67001f', 2  => '#b2182b', 3  => '#d6604d', 4  => '#f4a582', 
    5  => '#fddbc7', 6  => '#f7f7f7', 7  => '#d1e5f0', 8  => '#92c5de', 
    9  => '#4393c3', 10  => '#2166ac', 11  => '#053061', 
  },
  rdbu3 => {
    1  => '#ef8a62', 2  => '#f7f7f7', 3  => '#67a9cf', 
  },
  rdbu4 => {
    1  => '#ca0020', 2  => '#f4a582', 3  => '#92c5de', 4  => '#0571b0', 
  },
  rdbu5 => {
    1  => '#ca0020', 2  => '#f4a582', 3  => '#f7f7f7', 4  => '#92c5de', 
    5  => '#0571b0', 
  },
  rdbu6 => {
    1  => '#b2182b', 2  => '#ef8a62', 3  => '#fddbc7', 4  => '#d1e5f0', 
    5  => '#67a9cf', 6  => '#2166ac', 
  },
  rdbu7 => {
    1  => '#b2182b', 2  => '#ef8a62', 3  => '#fddbc7', 4  => '#f7f7f7', 
    5  => '#d1e5f0', 6  => '#67a9cf', 7  => '#2166ac', 
  },
  rdbu8 => {
    1  => '#b2182b', 2  => '#d6604d', 3  => '#f4a582', 4  => '#fddbc7', 
    5  => '#d1e5f0', 6  => '#92c5de', 7  => '#4393c3', 8  => '#2166ac', 
  },
  rdbu9 => {
    1  => '#b2182b', 2  => '#d6604d', 3  => '#f4a582', 4  => '#fddbc7', 
    5  => '#f7f7f7', 6  => '#d1e5f0', 7  => '#92c5de', 8  => '#4393c3', 
    9  => '#2166ac', 
  },
  rdgy3 => {
    1  => '#ef8a62', 2  => '#ffffff', 3  => '#999999', 
  },
  rdgy4 => {
    1  => '#ca0020', 2  => '#f4a582', 3  => '#bababa', 4  => '#404040', 
  },
  rdgy5 => {
    1  => '#ca0020', 2  => '#f4a582', 3  => '#ffffff', 4  => '#bababa', 
    5  => '#404040', 
  },
  rdgy6 => {
    1  => '#b2182b', 2  => '#ef8a62', 3  => '#fddbc7', 4  => '#e0e0e0', 
    5  => '#999999', 6  => '#4d4d4d', 
  },
  rdgy7 => {
    1  => '#b2182b', 2  => '#ef8a62', 3  => '#fddbc7', 4  => '#ffffff', 
    5  => '#e0e0e0', 6  => '#999999', 7  => '#4d4d4d', 
  },
  rdgy8 => {
    1  => '#b2182b', 2  => '#d6604d', 3  => '#f4a582', 4  => '#fddbc7', 
    5  => '#e0e0e0', 6  => '#bababa', 7  => '#878787', 8  => '#4d4d4d', 
  },
  rdgy9 => {
    1  => '#b2182b', 2  => '#d6604d', 3  => '#f4a582', 4  => '#fddbc7', 
    5  => '#ffffff', 6  => '#e0e0e0', 7  => '#bababa', 8  => '#878787', 
    9  => '#4d4d4d', 
  },
  rdpu3 => {
    1  => '#fde0dd', 2  => '#fa9fb5', 3  => '#c51b8a', 
  },
  rdpu4 => {
    1  => '#feebe2', 2  => '#fbb4b9', 3  => '#f768a1', 4  => '#ae017e', 
  },
  rdpu5 => {
    1  => '#feebe2', 2  => '#fbb4b9', 3  => '#f768a1', 4  => '#c51b8a', 
    5  => '#7a0177', 
  },
  rdpu6 => {
    1  => '#feebe2', 2  => '#fcc5c0', 3  => '#fa9fb5', 4  => '#f768a1', 
    5  => '#c51b8a', 6  => '#7a0177', 
  },
  rdpu7 => {
    1  => '#feebe2', 2  => '#fcc5c0', 3  => '#fa9fb5', 4  => '#f768a1', 
    5  => '#dd3497', 6  => '#ae017e', 7  => '#7a0177', 
  },
  rdpu8 => {
    1  => '#fff7f3', 2  => '#fde0dd', 3  => '#fcc5c0', 4  => '#fa9fb5', 
    5  => '#f768a1', 6  => '#dd3497', 7  => '#ae017e', 8  => '#7a0177', 
  },
  rdpu9 => {
    1  => '#fff7f3', 2  => '#fde0dd', 3  => '#fcc5c0', 4  => '#fa9fb5', 
    5  => '#f768a1', 6  => '#dd3497', 7  => '#ae017e', 8  => '#7a0177', 
    9  => '#49006a', 
  },
  rdgy10 => {
    1  => '#67001f', 2  => '#b2182b', 3  => '#d6604d', 4  => '#f4a582', 
    5  => '#fddbc7', 6  => '#e0e0e0', 7  => '#bababa', 8  => '#878787', 
    9  => '#4d4d4d', 10  => '#1a1a1a', 
  },
  rdgy11 => {
    1  => '#67001f', 2  => '#b2182b', 3  => '#d6604d', 4  => '#f4a582', 
    5  => '#fddbc7', 6  => '#ffffff', 7  => '#e0e0e0', 8  => '#bababa', 
    9  => '#878787', 10  => '#4d4d4d', 11  => '#1a1a1a', 
  },
  rdylbu3 => {
    1  => '#fc8d59', 2  => '#ffffbf', 3  => '#91bfdb', 
  },
  rdylbu4 => {
    1  => '#d7191c', 2  => '#fdae61', 3  => '#abd9e9', 4  => '#2c7bb6', 
  },
  rdylbu5 => {
    1  => '#d7191c', 2  => '#fdae61', 3  => '#ffffbf', 4  => '#abd9e9', 
    5  => '#2c7bb6', 
  },
  rdylbu6 => {
    1  => '#d73027', 2  => '#fc8d59', 3  => '#fee090', 4  => '#e0f3f8', 
    5  => '#91bfdb', 6  => '#4575b4', 
  },
  rdylbu7 => {
    1  => '#d73027', 2  => '#fc8d59', 3  => '#fee090', 4  => '#ffffbf', 
    5  => '#e0f3f8', 6  => '#91bfdb', 7  => '#4575b4', 
  },
  rdylbu8 => {
    1  => '#d73027', 2  => '#f46d43', 3  => '#fdae61', 4  => '#fee090', 
    5  => '#e0f3f8', 6  => '#abd9e9', 7  => '#74add1', 8  => '#4575b4', 
  },
  rdylbu9 => {
    1  => '#d73027', 2  => '#f46d43', 3  => '#fdae61', 4  => '#fee090', 
    5  => '#ffffbf', 6  => '#e0f3f8', 7  => '#abd9e9', 8  => '#74add1', 
    9  => '#4575b4', 
  },
  rdylbu10 => {
    1  => '#a50026', 2  => '#d73027', 3  => '#f46d43', 4  => '#fdae61', 
    5  => '#fee090', 6  => '#e0f3f8', 7  => '#abd9e9', 8  => '#74add1', 
    9  => '#4575b4', 10  => '#313695', 
  },
  rdylbu11 => {
    1  => '#a50026', 2  => '#d73027', 3  => '#f46d43', 4  => '#fdae61', 
    5  => '#fee090', 6  => '#ffffbf', 7  => '#e0f3f8', 8  => '#abd9e9', 
    9  => '#74add1', 10  => '#4575b4', 11  => '#313695', 
  },
  rdylgn3 => {
    1  => '#fc8d59', 2  => '#ffffbf', 3  => '#91cf60', 
  },
  rdylgn4 => {
    1  => '#d7191c', 2  => '#fdae61', 3  => '#a6d96a', 4  => '#1a9641', 
  },
  rdylgn5 => {
    1  => '#d7191c', 2  => '#fdae61', 3  => '#ffffbf', 4  => '#a6d96a', 
    5  => '#1a9641', 
  },
  rdylgn6 => {
    1  => '#d73027', 2  => '#fc8d59', 3  => '#fee08b', 4  => '#d9ef8b', 
    5  => '#91cf60', 6  => '#1a9850', 
  },
  rdylgn7 => {
    1  => '#d73027', 2  => '#fc8d59', 3  => '#fee08b', 4  => '#ffffbf', 
    5  => '#d9ef8b', 6  => '#91cf60', 7  => '#1a9850', 
  },
  rdylgn8 => {
    1  => '#d73027', 2  => '#f46d43', 3  => '#fdae61', 4  => '#fee08b', 
    5  => '#d9ef8b', 6  => '#a6d96a', 7  => '#66bd63', 8  => '#1a9850', 
  },
  rdylgn9 => {
    1  => '#d73027', 2  => '#f46d43', 3  => '#fdae61', 4  => '#fee08b', 
    5  => '#ffffbf', 6  => '#d9ef8b', 7  => '#a6d96a', 8  => '#66bd63', 
    9  => '#1a9850', 
  },
  rdylgn10 => {
    1  => '#a50026', 2  => '#d73027', 3  => '#f46d43', 4  => '#fdae61', 
    5  => '#fee08b', 6  => '#d9ef8b', 7  => '#a6d96a', 8  => '#66bd63', 
    9  => '#1a9850', 10  => '#006837', 
  },
  rdylgn11 => {
    1  => '#a50026', 2  => '#d73027', 3  => '#f46d43', 4  => '#fdae61', 
    5  => '#fee08b', 6  => '#ffffbf', 7  => '#d9ef8b', 8  => '#a6d96a', 
    9  => '#66bd63', 10  => '#1a9850', 11  => '#006837', 
  },
  reds3 => {
    1  => '#fee0d2', 2  => '#fc9272', 3  => '#de2d26', 
  },
  reds4 => {
    1  => '#fee5d9', 2  => '#fcae91', 3  => '#fb6a4a', 4  => '#cb181d', 
  },
  reds5 => {
    1  => '#fee5d9', 2  => '#fcae91', 3  => '#fb6a4a', 4  => '#de2d26', 
    5  => '#a50f15', 
  },
  reds6 => {
    1  => '#fee5d9', 2  => '#fcbba1', 3  => '#fc9272', 4  => '#fb6a4a', 
    5  => '#de2d26', 6  => '#a50f15', 
  },
  reds7 => {
    1  => '#fee5d9', 2  => '#fcbba1', 3  => '#fc9272', 4  => '#fb6a4a', 
    5  => '#ef3b2c', 6  => '#cb181d', 7  => '#99000d', 
  },
  reds8 => {
    1  => '#fff5f0', 2  => '#fee0d2', 3  => '#fcbba1', 4  => '#fc9272', 
    5  => '#fb6a4a', 6  => '#ef3b2c', 7  => '#cb181d', 8  => '#99000d', 
  },
  reds9 => {
    1  => '#fff5f0', 2  => '#fee0d2', 3  => '#fcbba1', 4  => '#fc9272', 
    5  => '#fb6a4a', 6  => '#ef3b2c', 7  => '#cb181d', 8  => '#a50f15', 
    9  => '#67000d', 
  },
  set13 => {
    1  => '#e41a1c', 2  => '#377eb8', 3  => '#4daf4a', 
  },
  set14 => {
    1  => '#e41a1c', 2  => '#377eb8', 3  => '#4daf4a', 4  => '#984ea3', 
  },
  set15 => {
    1  => '#e41a1c', 2  => '#377eb8', 3  => '#4daf4a', 4  => '#984ea3', 
    5  => '#ff7f00', 
  },
  set16 => {
    1  => '#e41a1c', 2  => '#377eb8', 3  => '#4daf4a', 4  => '#984ea3', 
    5  => '#ff7f00', 6  => '#ffff33', 
  },
  set17 => {
    1  => '#e41a1c', 2  => '#377eb8', 3  => '#4daf4a', 4  => '#984ea3', 
    5  => '#ff7f00', 6  => '#ffff33', 7  => '#a65628', 
  },
  set18 => {
    1  => '#e41a1c', 2  => '#377eb8', 3  => '#4daf4a', 4  => '#984ea3', 
    5  => '#ff7f00', 6  => '#ffff33', 7  => '#a65628', 8  => '#f781bf', 
  },
  set19 => {
    1  => '#e41a1c', 2  => '#377eb8', 3  => '#4daf4a', 4  => '#984ea3', 
    5  => '#ff7f00', 6  => '#ffff33', 7  => '#a65628', 8  => '#f781bf', 
    9  => '#999999', 
  },
  set23 => {
    1  => '#66c2a5', 2  => '#fc8d62', 3  => '#8da0cb', 
  },
  set24 => {
    1  => '#66c2a5', 2  => '#fc8d62', 3  => '#8da0cb', 4  => '#e78ac3', 
  },
  set25 => {
    1  => '#66c2a5', 2  => '#fc8d62', 3  => '#8da0cb', 4  => '#e78ac3', 
    5  => '#a6d854', 
  },
  set26 => {
    1  => '#66c2a5', 2  => '#fc8d62', 3  => '#8da0cb', 4  => '#e78ac3', 
    5  => '#a6d854', 6  => '#ffd92f', 
  },
  set27 => {
    1  => '#66c2a5', 2  => '#fc8d62', 3  => '#8da0cb', 4  => '#e78ac3', 
    5  => '#a6d854', 6  => '#ffd92f', 7  => '#e5c494', 
  },
  set28 => {
    1  => '#66c2a5', 2  => '#fc8d62', 3  => '#8da0cb', 4  => '#e78ac3', 
    5  => '#a6d854', 6  => '#ffd92f', 7  => '#e5c494', 8  => '#b3b3b3', 
  },
  set33 => {
    1  => '#8dd3c7', 2  => '#ffffb3', 3  => '#bebada', 
  },
  set34 => {
    1  => '#8dd3c7', 2  => '#ffffb3', 3  => '#bebada', 4  => '#fb8072', 
  },
  set35 => {
    1  => '#8dd3c7', 2  => '#ffffb3', 3  => '#bebada', 4  => '#fb8072', 
    5  => '#80b1d3', 
  },
  set36 => {
    1  => '#8dd3c7', 2  => '#ffffb3', 3  => '#bebada', 4  => '#fb8072', 
    5  => '#80b1d3', 6  => '#fdb462', 
  },
  set37 => {
    1  => '#8dd3c7', 2  => '#ffffb3', 3  => '#bebada', 4  => '#fb8072', 
    5  => '#80b1d3', 6  => '#fdb462', 7  => '#b3de69', 
  },
  set38 => {
    1  => '#8dd3c7', 2  => '#ffffb3', 3  => '#bebada', 4  => '#fb8072', 
    5  => '#80b1d3', 6  => '#fdb462', 7  => '#b3de69', 8  => '#fccde5', 
  },
  set39 => {
    1  => '#8dd3c7', 2  => '#ffffb3', 3  => '#bebada', 4  => '#fb8072', 
    5  => '#80b1d3', 6  => '#fdb462', 7  => '#b3de69', 8  => '#fccde5', 
    9  => '#d9d9d9', 
  },
  set310 => {
    1  => '#8dd3c7', 2  => '#ffffb3', 3  => '#bebada', 4  => '#fb8072', 
    5  => '#80b1d3', 6  => '#fdb462', 7  => '#b3de69', 8  => '#fccde5', 
    9  => '#d9d9d9', 10  => '#bc80bd', 
  },
  set311 => {
    1  => '#8dd3c7', 2  => '#ffffb3', 3  => '#bebada', 4  => '#fb8072', 
    5  => '#80b1d3', 6  => '#fdb462', 7  => '#b3de69', 8  => '#fccde5', 
    9  => '#d9d9d9', 10  => '#bc80bd', 11  => '#ccebc5', 
  },
  set312 => {
    1  => '#8dd3c7', 2  => '#ffffb3', 3  => '#bebada', 4  => '#fb8072', 
    5  => '#80b1d3', 6  => '#fdb462', 7  => '#b3de69', 8  => '#fccde5', 
    9  => '#d9d9d9', 10  => '#bc80bd', 11  => '#ccebc5', 12  => '#ffed6f', 
  },
  spectral3 => {
    1  => '#fc8d59', 2  => '#ffffbf', 3  => '#99d594', 
  },
  spectral4 => {
    1  => '#d7191c', 2  => '#fdae61', 3  => '#abdda4', 4  => '#2b83ba', 
  },
  spectral5 => {
    1  => '#d7191c', 2  => '#fdae61', 3  => '#ffffbf', 4  => '#abdda4', 
    5  => '#2b83ba', 
  },
  spectral6 => {
    1  => '#d53e4f', 2  => '#fc8d59', 3  => '#fee08b', 4  => '#e6f598', 
    5  => '#99d594', 6  => '#3288bd', 
  },
  spectral7 => {
    1  => '#d53e4f', 2  => '#fc8d59', 3  => '#fee08b', 4  => '#ffffbf', 
    5  => '#e6f598', 6  => '#99d594', 7  => '#3288bd', 
  },
  spectral8 => {
    1  => '#d53e4f', 2  => '#f46d43', 3  => '#fdae61', 4  => '#fee08b', 
    5  => '#e6f598', 6  => '#abdda4', 7  => '#66c2a5', 8  => '#3288bd', 
  },
  spectral9 => {
    1  => '#d53e4f', 2  => '#f46d43', 3  => '#fdae61', 4  => '#fee08b', 
    5  => '#ffffbf', 6  => '#e6f598', 7  => '#abdda4', 8  => '#66c2a5', 
    9  => '#3288bd', 
  },
  spectral10 => {
    1  => '#9e0142', 2  => '#d53e4f', 3  => '#f46d43', 4  => '#fdae61', 
    5  => '#fee08b', 6  => '#e6f598', 7  => '#abdda4', 8  => '#66c2a5', 
    9  => '#3288bd', 10  => '#5e4fa2', 
  },
  spectral11 => {
    1  => '#9e0142', 2  => '#d53e4f', 3  => '#f46d43', 4  => '#fdae61', 
    5  => '#fee08b', 6  => '#ffffbf', 7  => '#e6f598', 8  => '#abdda4', 
    9  => '#66c2a5', 10  => '#3288bd', 11  => '#5e4fa2', 
  },
  ylgn3 => {
    1  => '#f7fcb9', 2  => '#addd8e', 3  => '#31a354', 
  },
  ylgn4 => {
    1  => '#ffffcc', 2  => '#c2e699', 3  => '#78c679', 4  => '#238443', 
  },
  ylgn5 => {
    1  => '#ffffcc', 2  => '#c2e699', 3  => '#78c679', 4  => '#31a354', 
    5  => '#006837', 
  },
  ylgn6 => {
    1  => '#ffffcc', 2  => '#d9f0a3', 3  => '#addd8e', 4  => '#78c679', 
    5  => '#31a354', 6  => '#006837', 
  },
  ylgn7 => {
    1  => '#ffffcc', 2  => '#d9f0a3', 3  => '#addd8e', 4  => '#78c679', 
    5  => '#41ab5d', 6  => '#238443', 7  => '#005a32', 
  },
  ylgn8 => {
    1  => '#ffffe5', 2  => '#f7fcb9', 3  => '#d9f0a3', 4  => '#addd8e', 
    5  => '#78c679', 6  => '#41ab5d', 7  => '#238443', 8  => '#005a32', 
  },
  ylgn9 => {
    1  => '#ffffe5', 2  => '#f7fcb9', 3  => '#d9f0a3', 4  => '#addd8e', 
    5  => '#78c679', 6  => '#41ab5d', 7  => '#238443', 8  => '#006837', 
    9  => '#004529', 
  },
  ylgnbu3 => {
    1  => '#edf8b1', 2  => '#7fcdbb', 3  => '#2c7fb8', 
  },
  ylgnbu4 => {
    1  => '#ffffcc', 2  => '#a1dab4', 3  => '#41b6c4', 4  => '#225ea8', 
  },
  ylgnbu5 => {
    1  => '#ffffcc', 2  => '#a1dab4', 3  => '#41b6c4', 4  => '#2c7fb8', 
    5  => '#253494', 
  },
  ylgnbu6 => {
    1  => '#ffffcc', 2  => '#c7e9b4', 3  => '#7fcdbb', 4  => '#41b6c4', 
    5  => '#2c7fb8', 6  => '#253494', 
  },
  ylgnbu7 => {
    1  => '#ffffcc', 2  => '#c7e9b4', 3  => '#7fcdbb', 4  => '#41b6c4', 
    5  => '#1d91c0', 6  => '#225ea8', 7  => '#0c2c84', 
  },
  ylgnbu8 => {
    1  => '#ffffd9', 2  => '#edf8b1', 3  => '#c7e9b4', 4  => '#7fcdbb', 
    5  => '#41b6c4', 6  => '#1d91c0', 7  => '#225ea8', 8  => '#0c2c84', 
  },
  ylgnbu9 => {
    1  => '#ffffd9', 2  => '#edf8b1', 3  => '#c7e9b4', 4  => '#7fcdbb', 
    5  => '#41b6c4', 6  => '#1d91c0', 7  => '#225ea8', 8  => '#253494', 
    9  => '#081d58', 
  },
  ylorbr3 => {
    1  => '#fff7bc', 2  => '#fec44f', 3  => '#d95f0e', 
  },
  ylorbr4 => {
    1  => '#ffffd4', 2  => '#fed98e', 3  => '#fe9929', 4  => '#cc4c02', 
  },
  ylorbr5 => {
    1  => '#ffffd4', 2  => '#fed98e', 3  => '#fe9929', 4  => '#d95f0e', 
    5  => '#993404', 
  },
  ylorbr6 => {
    1  => '#ffffd4', 2  => '#fee391', 3  => '#fec44f', 4  => '#fe9929', 
    5  => '#d95f0e', 6  => '#993404', 
  },
  ylorbr7 => {
    1  => '#ffffd4', 2  => '#fee391', 3  => '#fec44f', 4  => '#fe9929', 
    5  => '#ec7014', 6  => '#cc4c02', 7  => '#8c2d04', 
  },
  ylorbr8 => {
    1  => '#ffffe5', 2  => '#fff7bc', 3  => '#fee391', 4  => '#fec44f', 
    5  => '#fe9929', 6  => '#ec7014', 7  => '#cc4c02', 8  => '#8c2d04', 
  },
  ylorbr9 => {
    1  => '#ffffe5', 2  => '#fff7bc', 3  => '#fee391', 4  => '#fec44f', 
    5  => '#fe9929', 6  => '#ec7014', 7  => '#cc4c02', 8  => '#993404', 
    9  => '#662506', 
  },
  ylorrd3 => {
    1  => '#ffeda0', 2  => '#feb24c', 3  => '#f03b20', 
  },
  ylorrd4 => {
    1  => '#ffffb2', 2  => '#fecc5c', 3  => '#fd8d3c', 4  => '#e31a1c', 
  },
  ylorrd5 => {
    1  => '#ffffb2', 2  => '#fecc5c', 3  => '#fd8d3c', 4  => '#f03b20', 
    5  => '#bd0026', 
  },
  ylorrd6 => {
    1  => '#ffffb2', 2  => '#fed976', 3  => '#feb24c', 4  => '#fd8d3c', 
    5  => '#f03b20', 6  => '#bd0026', 
  },
  ylorrd7 => {
    1  => '#ffffb2', 2  => '#fed976', 3  => '#feb24c', 4  => '#fd8d3c', 
    5  => '#fc4e2a', 6  => '#e31a1c', 7  => '#b10026', 
  },
  ylorrd8 => {
    1  => '#ffffcc', 2  => '#ffeda0', 3  => '#fed976', 4  => '#feb24c', 
    5  => '#fd8d3c', 6  => '#fc4e2a', 7  => '#e31a1c', 8  => '#b10026', 
  },
  ylorrd9 => {
    1  => '#ffffcc', 2  => '#ffeda0', 3  => '#fed976', 4  => '#feb24c', 
    5  => '#fd8d3c', 6  => '#fc4e2a', 7  => '#e31a1c', 8  => '#bd0026', 
    9  => '#800026', 
  },
  };

# reverse mapping value => name
my $color_values = { };
my $all_color_names = { };

{
  # reverse mapping "#ff0000 => 'red'"
  # also build a list of all possible color names
  for my $n (keys %$color_names)
    {
    my $s = $color_names->{$n};
    $color_values->{ $n } = {};
    my $t = $color_values->{$n};
    # sort the names on their length
    for my $c (sort { length($a) <=> length($b) || $a cmp $b } keys %$s)
      {
      # don't add "blue1" if it is already set as "blue"
      $t->{ $s->{$c} } = $c unless exists $t->{ $s->{$c} };
      # mark as existing
      $all_color_names->{ $c } = undef;
      }
    }
}

our $qr_custom_attribute = qr/^x-([a-z_0-9]+-)*[a-z_0-9]+\z/;

sub color_names
  {
  $color_names;
  }

sub color_name
  {
  # return "red" for "#ff0000"
  my ($self,$color,$scheme) = @_;

  $scheme ||= 'w3c';
  $color_values->{$scheme}->{$color} || $color;
  }

sub color_value
  {
  # return "#ff0000" for "red"
  my ($self,$color,$scheme) = @_;

  $scheme ||= 'w3c';

  # 'w3c/red' => 'w3c', 'red'
  $scheme = $1 if $color =~ s/^([a-z0-9])\///;

  $color_names->{$scheme}->{$color} || $color;
  }

sub _color_scheme
  {
  # check that a given color scheme is valid
  my ($self, $scheme) = @_;

  return $scheme if $scheme eq 'inherit';
  exists $color_names->{ $scheme } ? $scheme : undef;
  }

sub _color
  {
  # Check that a given color name (like 'red'), or value (like '#ff0000')
  # or rgb(1,2,3) is valid. Used by valid_attribute().

  # Note that for color names, the color scheme is not known here, so we
  # can only look if the color name is potentially possible. F.i. under
  # the Brewer scheme ylorrd9, '1' is a valid color name, while 'red'
  # would not. To resolve such conflicts, we will fallback to 'x11'
  # (the largest of the schemes) if the color name doesn't exist in
  # the current scheme.
  my ($self, $org_color) = @_;

  $org_color = lc($org_color);		# color names are case insensitive
  $org_color =~ s/\s//g;		# remove spaces to unify format
  my $color = $org_color;

  if ($color =~ s/^(w3c|[a-z]+\d{0,2})\///)
    {
    my $scheme = $1;
    return $org_color if exists $color_names->{$scheme}->{$color};
    # if it didn't work, then fall back to x11
    $scheme = 'x11';
    return (exists $color_names->{$scheme}->{$color} ? $org_color : undef);
    }

  # scheme unknown, fall back to generic handling

  # red => red
  return $org_color if exists $all_color_names->{$color};

  # #ff0000 => #ff0000, rgb(1,2,3) => rgb(1,2,3)
  defined $self->color_as_hex($color) ? $org_color : undef;
  }

sub _hsv_to_rgb
  {
  # H=0..360, S=0..1.0, V=0..1.0
  my ($h, $s, $v) = @_;

  my $e = 0.0001;

  if ($s < $e)
    {
    $v = abs(int(256 * $v)); $v = 255 if $v > 255;
    return ($v,$v,$v);
    }

  my ($r,$g,$b);
  $h *= 360;

  my $h1 = int($h / 60);
  my $f = $h / 60 - $h1;
  my $p = $v * (1 - $s);
  my $q = $v * (1 - ($s * $f));
  my $t = $v * (1 - ($s * (1-$f)));

  if ($h1 == 0 || $h1 == 6)
    {
    $r = $v; $g = $t; $b = $p;
    }
  elsif ($h1 == 1)
    {
    $r = $q; $g = $v; $b = $p;
    }
  elsif ($h1 == 2)
    {
    $r = $p; $g = $v; $b = $t;
    }
  elsif ($h1 == 3)
    {
    $r = $p; $g = $q; $b = $v;
    }
  elsif ($h1 == 4)
    {
    $r = $t; $g = $p; $b = $v;
    }
  else
    {
    $r = $v; $g = $p; $b = $q;
    }
  # clamp values to 0.255
  $r = abs(int($r*256));
  $g = abs(int($g*256));
  $b = abs(int($b*256));
  $r = 255 if $r > 255;
  $g = 255 if $g > 255;
  $b = 255 if $b > 255;

  ($r,$g,$b);
  }

sub _hsl_to_rgb
  {
  # H=0..360, S=0..100, L=0..100
  my ($h, $s, $l) = @_;

  my $e = 0.0001;
  if ($s < $e)
    {
    # achromatic or grey
    $l = abs(int(256 * $l)); $l = 255 if $l > 255;
    return ($l,$l,$l);
    }

  my $t2;
  if ($l < 0.5)
    {
    $t2 = $l * ($s + 1);
    }
  else
    {
    $t2 = $l + $s - ($l * $s);
    }
  my $t1 = $l * 2 - $t2;

  my ($r,$g,$b);

  # 0..359
  $h %= 360 if $h >= 360;

  # $h = 0..1
  $h /= 360;

  my $tr = $h + 1/3;
  my $tg = $h;
  my $tb = $h - 1/3;

  $tr += 1 if $tr < 0; $tr -= 1 if $tr > 1;
  $tg += 1 if $tg < 0; $tg -= 1 if $tg > 1;
  $tb += 1 if $tb < 0; $tb -= 1 if $tb > 1;

  my $i = 0; my @temp3 = ($tr,$tg,$tb);
  my @rc;
  for my $c ($r,$g,$b)
    {
    my $t3 = $temp3[$i++];

    if ($t3 < 1/6)
      {
      $c = $t1 + ($t2 - $t1) * 6 * $t3;
      }
    elsif ($t3 < 1/2)
      {
      $c = $t2;
      }
    elsif ($t3 < 2/3)
      {
      $c = $t1 + ($t2 - $t1) * 6 * (2/3 - $t3);
      }
    else
      {
      $c = $t1;
      }
    $c = int($c * 256); $c = 255 if $c > 255;
    push @rc, $c;
    }

  @rc;
  }

my $factors = {
  'rgb' => [ 255, 255, 255, 255 ],
  'hsv' => [ 1, 1, 1, 255 ],
  'hsl' => [ 360, 1, 1, 255 ],
  };

sub color_as_hex
  {
  # Turn "red" or rgb(255,0,0) or "#f00" into "#ff0000". Return undef for
  # invalid colors.
  my ($self,$color,$scheme) = @_;

  $scheme ||= 'w3c';
  $color = lc($color);
  # 'w3c/red' => 'w3c', 'red'
  $scheme = $1 if $color =~ s/^([a-z0-9])\///;

  # convert "red" to "ffff00"
  return $color_names->{$scheme}->{$color} 
   if exists $color_names->{$scheme}->{$color};

  # fallback to x11 scheme if color doesn't exist
  return $color_names->{x11}->{$color} 
   if exists $color_names->{x11}->{$color};

  my $qr_num = qr/\s*
	((?:[0-9]{1,3}%?) |		# 12%, 10, 2 etc
	 (?:[0-9]?\.[0-9]{1,5}) )	# .1, 0.1, 2.5 etc
    /x;

  # rgb(255,100%,1.0) => '#ffffff'
  if ($color =~ /^(rgb|hsv|hsl)\($qr_num,$qr_num,$qr_num(?:,$qr_num)?\s*\)\z/)
    {
    my $r = $2; my $g = $3; my $b = $4; my $a = $5; $a = 255 unless defined $a;
    my $format = $1;

    my $i = 0;
    for my $c ($r,$g,$b,$a)
      {
      # for the first value in HSL or HSV, use 360, otherwise 100. For RGB, use 255
      my $factor = $factors->{$format}->[$i++];

      if ($c =~ /^([0-9]+)%\z/)				# 10% => 25.5
	{
        $c = $1 * $factor / 100; 
	}
      else
	{
        $c = $1 * $factor if $c =~ /^([0-9]+\.[0-9]+)\z/;		# 0.1, 1.0
        }
      }

    ($r,$g,$b) = Graph::Easy::_hsv_to_rgb($r,$g,$b) if $format eq 'hsv';
    ($r,$g,$b) = Graph::Easy::_hsl_to_rgb($r,$g,$b) if $format eq 'hsl';

    $a = int($a); $a = 255 if $a > 255;

    # #RRGGBB or #RRGGBBAA
    $color = sprintf("#%02x%02x%02x%02x", $r,$g,$b,$a);
    }

  # turn #ff0 into #ffff00
  $color = "#$1$1$2$2$3$3" if $color =~ /^#([a-f0-9])([a-f0-9])([a-f[0-9])\z/;

  # #RRGGBBff => #RRGGBB (alpha value of 255 is the default)
  $color =~ s/^(#......)ff\z/$1/i;

  # check final color value to be #RRGGBB or #RRGGBBAA
  return undef unless $color =~ /^#([a-f0-9]{6}|[a-f0-9]{8})\z/i;

  $color;
  }

sub text_style
  {
  # check whether the given list of textstyle attributes is valid
  my ($self, $style) = @_;

  return $style if $style =~ /^(normal|none|)\z/;

  my @styles = split /\s+/, $style;
  
  return undef if grep(!/^(underline|overline|line-through|italic|bold)\z/, @styles);

  $style;
  }

sub text_styles
  {
  # return a hash with the defined textstyles checked
  my ($self) = @_;

  my $style = $self->attribute('textstyle');

  return { none => 1 } if $style =~ /^(normal|none)\z/;
  return { } if $style eq '';

  my $styles = {};
  for my $key ( split /\s+/, $style )
    {
    $styles->{$key} = 1;
    }
  $styles;
  }

sub text_styles_as_css
  {
  my ($self, $align, $fontsize) = @_;

  my $style = '';
  my $ts = $self->text_styles();

  $style .= " font-style: italic;" if $ts->{italic};
  $style .= " font-weight: bold;" if $ts->{bold};

  if ($ts->{underline} || $ts->{none} || $ts->{overline} || $ts->{'line-through'})
    {
    # XXX TODO: HTML does seem to allow only one of them
    my @s;
    foreach my $k (qw/underline overline line-through none/)
      {
      push @s, $k if $ts->{$k};
      }
    my $s = join(' ', @s);
    $style .= " text-decoration: $s;" if $s;
    }

  my $fs = $self->raw_attribute('fontsize');

  $style .= " font-size: $fs;" if $fs;

  if (!$align)
    {
    # XXX TODO: raw_attribute()?
    my $al = $self->attribute('align');
    $style .= " text-align: $al;" if $al;
    }

  $style;
  }

sub _font_size_in_pixels
  {
  my ($self, $em, $val) = @_;
  
  my $fs = $val; $fs = $self->attribute('fontsize') || '' if !defined $val;
  return $em if $fs eq '';

  if ($fs =~ /^([\d.]+)em\z/)
    {
    $fs = $1 * $em;
    }
  elsif ($fs =~ /^([\d.]+)%\z/)
    {
    $fs = ($1 / 100) * $em;
    }
  # this is discouraged:
  elsif ($fs =~ /^([\d.]+)px\z/)
    {
    $fs = int($1 || 5);
    }
  else
    {
    $self->error("Illegal fontsize '$fs'");
    }
  $fs;
  }

# direction modifier in degrees
my $modifier = {
  forward => 0, front => 0, left => -90, right => +90, back => +180,
  };

# map absolute direction to degrees
my $dirs = {
  up => 0, north => 0, down => 180, south => 180, west => 270, east => 90,
  0 => 0, 180 => 180, 90 => 90, 270 => 270,
  };

# map absolute direction to side (south etc)
my $sides = {
  north => 'north', 
  south => 'south', 
  east => 'east', 
  west => 'west', 
  up => 'north', 
  down => 'south',
  0 => 'north',
  180 => 'south',
  90 => 'east',
  270 => 'west',
  };

sub _direction_as_number
  {
  my ($self,$dir) = @_;

  my $d = $dirs->{$dir};
  $self->_croak("$dir is not an absolut direction") unless defined $d;

  $d;
  }

sub _direction_as_side
  {
  my ($self,$dir) = @_;

  return unless exists $sides->{$dir};
  $sides->{$dir};
  }

sub _flow_as_direction
  {
  # Take a flow direction (0,90,180,270 etc), and a new direction (left|south etc)
  # and return the new flow. south et al will stay, while left|right etc depend
  # on the incoming flow.
  my ($self, $inflow, $dir) = @_;

  # in=south and dir=forward => south
  # in=south and dir=back => north etc
  # in=south and dir=east => east 

#  return 90 unless defined $dir;

  if ($dir =~ /^(south|north|west|east|up|down|0|90|180|270)\z/)
    {
    # new direction is absolut, so inflow doesn't play a role
    # return 0,90,180 or 270
    return $dirs->{$dir};
    }

  my $in = $dirs->{$inflow};
  my $modifier = $modifier->{$dir};

  $self->_croak("$inflow,$dir results in undefined inflow") unless defined $in;
  $self->_croak("$inflow,$dir results in undefined modifier") unless defined $modifier;

  my $out = $in + $modifier;
  $out -= 360 while $out >= 360;	# normalize to 0..359
  $out += 360 while $out < 0;		# normalize to 0..359
  
  $out;
  }

sub _flow_as_side
  {
  # Take a flow direction (0,90,180,270 etc), and a new direction (left|south etc)
  # and return the new flow. south et al will stay, while left|right etc depend
  # on the incoming flow.
  my ($self, $inflow, $dir) = @_;

  # in=south and dir=forward => south
  # in=south and dir=back => north etc
  # in=south and dir=east => east 

#  return 90 unless defined $dir;

  if ($dir =~ /^(south|north|west|east|up|down|0|90|180|270)\z/)
    {
    # new direction is absolut, so inflow doesn't play a role
    # return east, west etc
    return $sides->{$dir};
    }

  my $in = $dirs->{$inflow};
  my $modifier = $modifier->{$dir};

  $self->_croak("$inflow,$dir results in undefined inflow") unless defined $in;
  $self->_croak("$inflow,$dir results in undefined modifier") unless defined $modifier;

  my $out = $in + $modifier;
  $out -= 360 if $out >= 360;	# normalize to 0..359
  
  $sides->{$out};
  }

sub _direction
  {
  # check that a direction (south etc) is valid
  my ($self, $dir) = @_;

  $dir =~ /^(south|east|west|north|down|up|0|90|180|270|front|forward|back|left|right)\z/ ? $dir : undef;
  }

sub _border_attribute_as_html
  {
  # Return "solid 1px red" from the individual border(style|color|width)
  # attributes, mainly for HTML output.
  my ($style, $width, $color, $scheme) = @_;

  $style ||= '';
  $width = '' unless defined $width;
  $color = '' unless defined $color;

  $color = Graph::Easy->color_as_hex($color,$scheme)||'' if $color !~ /^#/;

  return $style if $style =~ /^(none|)\z/;

  # width: 2px for double would collapse to one line
  $width = '' if $style =~ /^double/;

  # convert the style and widths to something HTML can understand

  $width = '0.5em' if $style eq 'broad';
  $width = '4px' if $style =~ /^bold/;
  $width = '1em' if $style eq 'wide';
  $style = 'solid' if $style =~ /(broad|wide|bold)\z/;
  $style = 'dashed' if $style eq 'bold-dash';
  $style = 'double' if $style eq 'double-dash';

  $width = $width.'px' if $width =~ /^\s*\d+\s*\z/;

  return '' if $width eq '' && $style ne 'double';

  my $val = join(" ", $style, $width, $color);
  $val =~ s/^\s+//;
  $val =~ s/\s+\z//;

  $val;
  }

sub _border_attribute
  {
  # Return "solid 1px red" from the individual border(style|color|width)
  # attributes. Used by as_txt().
  my ($style, $width, $color) = @_;

  $style ||= '';
  $width = '' unless defined $width;
  $color = '' unless defined $color;

  return $style if $style =~ /^(none|)\z/;

  $width = $width.'px' if $width =~ /^\s*\d+\s*\z/;

  my $val = join(" ", $style, $width, $color);
  $val =~ s/^\s+//;
  $val =~ s/\s+\z//;

  $val;
  }

sub _border_width_in_pixels
  {
  my ($self, $em) = @_;
  
  my $bw = $self->attribute('borderwidth') || '0';
  return 0 if $bw eq '0';

  my $bs = $self->attribute('borderstyle') || 'none';

  return 0 if $bs eq 'none';
  return 3 if $bs =~ /^bold/;
  return $em / 2 if $bs =~ /^broad/;
  return $em if $bs =~ /^wide/;

  # width: 1 is 1px;
  return $bw if $bw =~ /^([\d.]+)\z/;

  if ($bw =~ /^([\d.]+)em\z/)
    {
    $bw = $1 * $em;
    }
  elsif ($bw =~ /^([\d.]+)%\z/)
    {
    $bw = ($1 / 100) * $em;
    }
  # this is discouraged:
  elsif ($bw =~ /^([\d.]+)px\z/)
    {
    $bw = $1;
    }
  else
    {
    $self->error("Illegal borderwidth '$bw'");
    }
  $bw;
  }

sub _angle
  {
  # check an angle for being valid
  my ($self, $angle) = @_;

  return undef unless $angle =~ /^([+-]?\d{1,3}|south|west|east|north|up|down|left|right|front|back|forward)\z/;

  $angle;
  }

sub _uint
  {
  # check a small unsigned integer for being valid
  my ($self, $val) = @_;

  return undef unless $val =~ /^\d+\z/;

  $val = abs(int($val));
  $val = 4 * 1024 if $val > 4 * 1024;

  $val;
  }

sub _font
  {
  # check a font-list for being valid
  my ($self, $font) = @_;

  $font;
  }

sub split_border_attributes
  {
  # split "1px solid black" or "red dotted" into style, width and color
  my ($self,$border) = @_;

  # special case
  return ('none', undef, undef) if $border eq '0';

  # extract style
  my $style;
  $border =~ 
   s/(solid|dotted|dot-dot-dash|dot-dash|dashed|double-dash|double|bold-dash|bold|broad|wide|wave|none)/$style=$1;''/eg;

  $style ||= 'solid';

  # extract width
  $border =~ s/(\d+(px|em|%))//g;

  my $width = $1 || '';
  $width =~ s/[^0-9]+//g;				# leave only digits

  $border =~ s/\s+//g;					# rem unnec. spaces

  # The left-over part must be a valid color. 
  my $color = $border;
  $color = Graph::Easy->_color($border) if $border ne '';

  $self->error("$border is not a valid bordercolor")
    unless defined $color;

  $width = undef if $width eq '';
  $color = undef if $color eq '';
  $style = undef if $style eq '';
  ($style,$width,$color);
  }

#############################################################################
# attribute checking

# different types of attributes with pre-defined handling
use constant {
  ATTR_STRING	=> 0,		# an arbitrary string
  ATTR_COLOR	=> 1,		# color name or value like rgb(1,1,1)
  ATTR_ANGLE	=> 2,		# 0 .. 359.99
  ATTR_PORT	=> 3,		# east, etc.
  ATTR_UINT	=> 4,		# a "small" unsigned integer
  ATTR_URL	=> 5,

# these cannot have "inherit", see ATTR_INHERIT_MIN
  ATTR_LIST	=> 6,		# a list of values
  ATTR_LCTEXT	=> 7,		# lowercase text (classname)
  ATTR_TEXT	=> 8,		# titles, links, labels etc

  ATTR_NO_INHERIT	=> 6,

  ATTR_DESC_SLOT	=> 0,
  ATTR_MATCH_SLOT	=> 1,
  ATTR_DEFAULT_SLOT	=> 2,
  ATTR_EXAMPLE_SLOT	=> 3,
  ATTR_TYPE_SLOT	=> 4,


  };

# Lists the attribute names along with
#   * a short description, 
#   * regexp or sub name to match valid attributes
#   * default value
#   * an short example value
#   * type
#   * graph examples

my $attributes = {
  all => {
    align => [
     "The alignment of the label text.",
     [ qw/center left right/ ],
     { default => 'center', group => 'left', edge => 'left' },
     'right',
     undef,
     "graph { align: left; label: My Graph; }\nnode {align: left;}\n ( Nodes:\n [ Right\\nAligned ] { align: right; } -- label\\n text -->\n { align: left; }\n [ Left\\naligned ] )",
     ],

    autolink => [
     "If set to something else than 'none', will use the appropriate attribute to automatically generate the L<link>, unless L<link> is already set. See the section about labels, titles, names and links for reference.",
     [ qw/label title name none inherit/ ],
     { default => 'inherit', graph => 'none' },
     'title',
     ],

    autotitle => [
     "If set to something else than 'none', will use the appropriate attribute to automatically generate the L<title>, unless L<title> is already set. See the section about labels, titles, names and links for reference.",
     [ qw/label name none link inherit/ ],
     { default => 'inherit', graph => 'none' },
     'label',
     ],

    autolabel => [
     "Will restrict the L<label> text to N characters. N must be greater than 10. See the section about labels, titles, names and links for reference.",
     # for compatibility with older versions (pre v0.49), also allow "name,N"
     qr/^(name\s*,\s*)?[\d]{2,5}\z/,
     { default => 'inherit', graph => '' },
     '20',
     undef,
     "graph { autolabel: 20; autotitle: name; }\n\n[ Bonn ]\n -- Acme Travels Incorporated -->\n  [ Frankfurt (Main) / Flughafen ]",
     ],

    background => [
     "The background color, e.g. the color B<outside> the shape. Do not confuse with L<fill>. If set to inherit, the object will inherit the L<fill> color (B<not> the background color!) of the parent e.g. the enclosing group or graph. See the section about color names and values for reference.",
     undef,
#     { default => 'inherit', graph => 'white', 'group.anon' => 'white', 'node.anon' => 'white' },
     'inherit',
     'rgb(255,0,0)',
     ATTR_COLOR,
     "[ Crimson ] { shape: circle; background: crimson; }\n -- Aqua Marine --> { background: #7fffd4; }\n [ Misty Rose ]\n  { background: white; fill: rgb(255,228,221); shape: ellipse; }",
     ],

    class => [
     'The subclass of the object. See the section about class names for reference.',
      qr/^(|[a-zA-Z][a-zA-Z0-9_]*)\z/,
     '',
     'mynodeclass',
     ATTR_LCTEXT,
     ],

    color => [
     'The foreground/text/label color. See the section about color names and values for reference.',
     undef,
     'black',
     'rgb(255,255,0)',
     ATTR_COLOR,
     "[ Lime ] { color: limegreen; }\n -- label --> { color: blue; labelcolor: red; }\n [ Dark Orange ] { color: rgb(255,50%,0.01); }",
     ],

    colorscheme => [
     "The colorscheme to use for all color values. See the section about color names and values for reference and a list of possible values.",
     '_color_scheme',
     { default => 'inherit', graph => 'w3c', },
     'x11',
     ATTR_STRING,
     "graph { colorscheme: accent8; } [ 1 ] { fill: 1; }\n"
        . " -> \n [ 3 ] { fill: 3; }\n" 
        . " -> \n [ 4 ] { fill: 4; }\n" 
        . " -> \n [ 5 ] { fill: 5; }\n" 
        . " -> \n [ 6 ] { fill: 6; }\n" 
        . " -> \n [ 7 ] { fill: 7; }\n" 
        . " -> \n [ 8 ] { fill: 8; }\n" ,
     ],

    comment => [
	"A free-form text field containing a comment on this object. This will be embedded into output formats if possible, e.g. in HTML, SVG and Graphviz, but not ASCII or Boxart.",
	undef,
	'',
	'(C) by Tels 2007. All rights reserved.',
	ATTR_STRING,
	"graph { comment: German capitals; }\n [ Bonn ] --> [ Berlin ]",
    ],

    fill => [
     "The fill color, e.g. the color inside the shape. For the graph, this is the background color for the label. For edges, defines the color inside the arrow shape. See also L<background>. See the section about color names and values for reference.",
     undef,
     { default => 'white', graph => 'inherit', edge => 'inherit', group => '#a0d0ff', 
	'group.anon' => 'white', 'node.anon' => 'inherit' },
     'rgb(255,0,0)',
     ATTR_COLOR,
     "[ Crimson ]\n  {\n  shape: circle;\n  background: yellow;\n  fill: red;\n  border: 3px solid blue;\n  }\n-- Aqua Marine -->\n  {\n  arrowstyle: filled;\n  fill: red;\n  }\n[ Two ]",
     ],

    'fontsize' => [
     "The size of the label text, best expressed in I<em> (1.0em, 0.5em etc) or percent (100%, 50% etc)",
     qr/^\d+(\.\d+)?(em|px|%)?\z/,
     { default => '0.8em', graph => '1em', node => '1em', },
     '50%',
     undef,
     "graph { fontsize: 200%; label: Sample; }\n\n ( Nodes:\n [ Big ] { fontsize: 1.5em; color: white; fill: darkred; }\n  -- Small -->\n { fontsize: 0.2em; }\n  [ Normal ] )",
     ],

    flow => [
     "The general direction in which edges will leave nodes first. On edges, influeces where the target node is place. Please see the section about <a href='hinting.html#flow'>flow control</a> for reference.",
     '_direction',
     { graph => 'east', default => 'inherit' },
     'south',
      undef,
      "graph { flow: up; }\n [ Enschede ] { flow: left; } -> [ Bielefeld ] -> [ Wolfsburg ]",
     ],

    font => [
     'A prioritized list of lower-case, unquoted values, separated by a comma. Values are either font family names (like "times", "arial" etc) or generic family names (like "serif", "cursive", "monospace"), the first recognized value will be used. Always offer a generic name as the last possibility.',
     '_font',
     { default => 'serif', edge => 'sans-serif' },
     'arial, helvetica, sans-serif',
     undef,
     "graph { font: vinque, georgia, utopia, serif; label: Sample; }" .
     "\n\n ( Nodes:\n [ Webdings ] { font: Dingbats, webdings; }\n".
     " -- FlatLine -->\n { font: flatline; }\n  [ Normal ] )",
     ],

    id => [
     "A unique identifier for this object, consisting only of letters, digits, or underscores.",
     qr/^[a-zA-Z0-9_]+\z/,
     '',
     'Bonn123',
     undef,
     "[ Bonn ] --> { id: 123; } [ Berlin ]",
     ],

    label => [
     "The text displayed as label. If not set, equals the name (for nodes) or no label (for edges, groups and the graph itself).",
     undef,
     undef,
     'My label',
     ATTR_TEXT,
     ],

    linkbase => [
     'The base URL prepended to all generated links. See the section about links for reference.',
     undef,
     { default => 'inherit', graph => '/wiki/index.php/', },
     'http://en.wikipedia.org/wiki/',
     ATTR_URL,
     ],

    link => [
     'The link part, appended onto L<linkbase>. See the section about links for reference.',
     undef,
     '',
     'Graph',
     ATTR_TEXT,
     <<LINK_EOF
node {
  autolink: name;
  textstyle: none;
  fontsize: 1.1em;
  }
graph {
  linkbase: http://de.wikipedia.org/wiki/;
  }
edge {
  textstyle: overline;
  }

[] --> [ Friedrichshafen ]
 -- Schiff --> { autolink: label; color: orange; title: Vrooom!; }
[ Immenstaad ] { color: green; } --> [ Hagnau ]
LINK_EOF
     ],

    title => [
     "The text displayed as mouse-over for nodes/edges, or as the title for the graph. If empty, no title will be generated unless L<autotitle> is set.",
     undef,
     '',
     'My title',
     ATTR_TEXT,
     ],

    format => [
     "The formatting language of the label. The default, C<none> means nothing special will be done. When set to C<pod>, formatting codes like <code>B&lt;bold&gt;</code> will change the formatting of the label. See the section about label text formatting for reference.",
     [ 'none', 'pod' ],
     'none',
     'pod',
     undef,
     <<EOF
graph {
  format: pod;
  label: I am B<bold> and I<italic>;
  }
node { format: pod; }
edge { format: pod; }

[ U<B<bold and underlined>> ]
--> { label: "S<Fähre>"; }
 [ O<Konstanz> ]
EOF
     ],

    textstyle => [
     "The style of the label text. Either 'none', or any combination (separated with spaces) of 'underline', 'overline', 'bold', 'italic', 'line-through'. 'none' disables underlines on links.",
     'text_style',
     '',
     'underline italic bold',
     undef,
     <<EOF
graph {
  fontsize: 150%;
  label: Verbindung;
  textstyle: bold italic;
  }
node {
  textstyle: underline bold;
  fill: #ffd080;
  }
edge {
  textstyle: italic bold overline;
  }

[ Meersburg ] { fontsize: 2em; }
 -- F\x{e4}hre --> { fontsize: 1.2em; color: red; }
 [ Konstanz ]
EOF
     ],

    textwrap => [
     "The default C<none> makes the label text appear exactly as it was written, with <a href='syntax.html'>manual line breaks</a> applied. When set to a positive number, the label text will be wrapped after this number of characters. When set to C<auto>, the label text will be wrapped to make the node size as small as possible, depending on output format this may even be dynamic. When not C<none>, manual line breaks and alignments on them are ignored.",
     qr/^(auto|none|\d{1,4})/,
     { default => 'inherit', graph => 'none' },
     'auto',
     undef,
     "node { textwrap: auto; }\n ( Nodes:\n [ Frankfurt (Oder) liegt an der\n   ostdeutschen Grenze und an der Oder ] -->\n [ Städte innerhalb der\n   Ost-Westfahlen Region mit sehr langen Namen] )",
     ],
   },

  node => {
    bordercolor => [
     'The color of the L<border>. See the section about color names and values for reference.',
     undef,
     { default => '#000000' },
     'rgb(255,255,0)',
     ATTR_COLOR,
     "node { border: black bold; }\n[ Black ]\n --> [ Red ]      { bordercolor: red; }\n --> [ Green ]    { bordercolor: green; }",
     ],

    borderstyle => [
     'The style of the L<border>. The special styles "bold", "broad", "wide", "double-dash" and "bold-dash" will set and override the L<borderwidth>.',
     [ qw/none solid dotted dashed dot-dash dot-dot-dash double wave bold bold-dash broad double-dash wide/ ],
     { default => 'none', 'node.anon' => 'none', 'group.anon' => 'none', node => 'solid', group => 'dashed' },
     'dotted',
     undef,
     "node { border: dotted; }\n[ Dotted ]\n --> [ Dashed ]      { borderstyle: dashed; }\n --> [ broad ]    { borderstyle: broad; }",
     ],

    borderwidth => [
     'The width of the L<border>. Certain L<border>-styles will override the width.',
     qr/^\d+(px|em)?\z/,
     '1',
     '2px',
     ],

    border => [
     'The border. Can be any combination of L<borderstyle>, L<bordercolor> and L<borderwidth>.',
     undef,
     { default => 'none', 'node.anon' => 'none', 'group.anon' => 'none', node => 'solid 1px #000000', group => 'dashed 1px #000000' },
     'dotted red',
     undef,
     "[ Normal ]\n --> [ Bold ]      { border: bold; }\n --> [ Broad ]     { border: broad; }\n --> [ Wide ]      { border: wide; }\n --> [ Bold-Dash ] { border: bold-dash; }",
     ],

    basename => [
     "Controls the base name of an autosplit node. Ignored for all other nodes. Unless set, it is generated automatically from the node parts. Please see the section about <a href='hinting.html#autosplit'>autosplit</a> for reference.",
     undef,
      '',
      '123',
       undef,
     "[ A|B|C ] { basename: A } [ 1 ] -> [ A.2 ]\n [ A|B|C ] [ 2 ] -> [ ABC.2 ]",
     ], 

    group => [
     "Puts the node into this group.",
     undef,
      '',
      'Cities',
       undef,
     "[ A ] { group: Cities:; } ( Cities: [ B ] ) [ A ] --> [ B ]",
     ], 

    size => [
     'The size of the node in columns and rows. Must be greater than 1 in each direction.',
     qr/^\d+\s*,\s*\d+\z/,
     '1,1',
     '3,2',
     ],
    rows => [
     'The size of the node in rows. See also L<size>.',
     qr/^\d+\z/,
     '1',
     '3',
     ],
    columns => [
     'The size of the node in columns. See also L<size>.',
     qr/^\d+\z/,
     '1',
     '2',
     ],

    offset => [
     'The offset of this node from the L<origin> node, in columns and rows. Only used if you also set the L<origin> node.',
     qr/^[+-]?\d+\s*,\s*[+-]?\d+\z/,
     '0,0',
     '3,2',
     undef,
     "[ A ] -> [ B ] { origin: A; offset: 2,2; }",
     ],

    origin => [
     'The name of the node, that this node is relativ to. See also L<offset>.',
     undef,
     '',
     'Cluster A',
     ],

    pointshape => [
     "Controls the style of a node that has a L<shape> of 'point'.",
     [ qw/star square dot circle cross diamond invisible x/ ],
      'star',
      'square',
      undef,
     "node { shape: point; }\n\n [ A ]".
     "\n -> [ B ] { pointshape: circle; }" .
     "\n -> [ C ] { pointshape: cross; }" . 
     "\n -> [ D ] { pointshape: diamond; }" . 
     "\n -> [ E ] { pointshape: dot; }" . 
     "\n -> [ F ] { pointshape: invisible; }" . 
     "\n -> [ G ] { pointshape: square; }" . 
     "\n -> [ H ] { pointshape: star; }" .
     "\n -> [ I ] { pointshape: x; }" .
     "\n -> [ ☯ ] { shape: none; }"
     ], 

    pointstyle => [
     "Controls the style of the L<pointshape> of a node that has a L<shape> of 'point'. " .
     "Note for backwards compatibility reasons, the shape names 'star', 'square', 'dot', 'circle', 'cross', 'diamond' and 'invisible' ".
     "are also supported, but should not be used here, instead set them via L<pointshape>.",
     [ qw/closed filled star square dot circle cross diamond invisible x/ ],
      'filled',
      'open',
      undef,
     "node { shape: point; pointstyle: closed; pointshape: diamond; }\n\n [ A ] --> [ B ] { pointstyle: filled; }",
     ], 

    rank => [
     "The rank of the node, used by the layouter to find the order and placement of nodes. " .
     "Set to C<auto> (the default), C<same> (usefull for node lists) or a positive number. " .
     "See the section about ranks for reference and more examples.",
       qr/^(auto|same|\d{1,6})\z/,
       'auto',
       'same',
       undef,
     "[ Bonn ], [ Berlin ] { rank: same; }\n [ Bonn ] -> [ Cottbus ] -> [ Berlin ]",
     ],

    rotate => [
     "The rotation of the node shape, either an absolute value (like C<south>, C<up>, C<down> or C<123>), or a relative value (like C<+12>, C<-90>, C<left>, C<right>). For relative angles, the rotation will be based on the node's L<flow>. Rotation is clockwise.",
       undef,
       '0',
       '180',
       ATTR_ANGLE,
     "[ Bonn ] { rotate: 45; } -- ICE --> \n [ Berlin ] { shape: triangle; rotate: -90; }",
     ],

    shape => [
     "The shape of the node. Nodes with shape 'point' (see L<pointshape>) have a fixed size and do not display their label. The border of such a node is the outline of the C<pointshape>, and the fill is the inside of the C<pointshape>. When the C<shape> is set to the value 'img', the L<label> will be interpreted as an external image resource to display. In this case attributes like L<color>, L<fontsize> etc. are ignored.",
       [ qw/ circle diamond edge ellipse hexagon house invisible invhouse invtrapezium invtriangle octagon parallelogram pentagon
             point triangle trapezium septagon rect rounded none img/ ],
      'rect',
      'circle',
      undef,
      "[ Bonn ] -> \n [ Berlin ] { shape: circle; }\n -> [ Regensburg ] { shape: rounded; }\n -> [ Ulm ] { shape: point; }\n -> [ Wasserburg ] { shape: invisible; }\n -> [ Augsburg ] { shape: triangle; }\n -> [ House ] { shape: img; label: img/house.png;\n          border: none; title: My House; fill: inherit; }",
     ],

  }, # node

  graph => {

    bordercolor => [
     'The color of the L<border>. See the section about color names and values for reference.',
     undef,
     { default => '#000000' },
     'rgb(255,255,0)',
     ATTR_COLOR,
     "node { border: black bold; }\n[ Black ]\n --> [ Red ]      { bordercolor: red; }\n --> [ Green ]    { bordercolor: green; }",
     ],

    borderstyle => [
     'The style of the L<border>. The special styles "bold", "broad", "wide", "double-dash" and "bold-dash" will set and override the L<borderwidth>.',
     [ qw/none solid dotted dashed dot-dash dot-dot-dash double wave bold bold-dash broad double-dash wide/ ],
     { default => 'none', 'node.anon' => 'none', 'group.anon' => 'none', node => 'solid', group => 'dashed' },
     'dotted',
     undef,
     "node { border: dotted; }\n[ Dotted ]\n --> [ Dashed ]      { borderstyle: dashed; }\n --> [ broad ]    { borderstyle: broad; }",
     ],

    borderwidth => [
     'The width of the L<border>. Certain L<border>-styles will override the width.',
     qr/^\d+(px|em)?\z/,
     '1',
     '2px',
     ],

    border => [
     'The border. Can be any combination of L<borderstyle>, L<bordercolor> and L<borderwidth>.',
     undef,
     { default => 'none', 'node.anon' => 'none', 'group.anon' => 'none', node => 'solid 1px #000000', group => 'dashed 1px #000000' },
     'dotted red',
     undef,
     "[ Normal ]\n --> [ Bold ]      { border: bold; }\n --> [ Broad ]     { border: broad; }\n --> [ Wide ]      { border: wide; }\n --> [ Bold-Dash ] { border: bold-dash; }",
     ],

    gid => [
	"A unique ID for the graph. Usefull if you want to include two graphs into one HTML page.",
	qr/^\d+\z/,
	'',
	'123',
     ],

    labelpos => [
	"The position of the graph label.",
	[ qw/top bottom/ ],
	'top',
	'bottom',
	ATTR_LIST,
        "graph { labelpos: bottom; label: My Graph; }\n\n [ Buxtehude ] -> [ Fuchsberg ]\n"
     ],

    output => [
	"The desired output format. Only used when calling Graph::Easy::output(), or by mediawiki-graph.",
	[ qw/ascii html svg graphviz boxart debug/ ],
	'',
	'ascii',
	ATTR_LIST,
        "graph { output: debug; }"
     ],

    root => [
	"The name of the root node, given as hint to the layouter to start the layout there. When not set, the layouter will pick a node at semi-random.",
	undef,
	'',
	'My Node',
	ATTR_TEXT,
	"graph { root: B; }\n # B will be at the left-most place\n [ A ] --> [ B ] --> [ C ] --> [ D ] --> [ A ]",
     ],

    type => [
	"The type of the graph, either undirected or directed.",
	[ qw/directed undirected/ ],
	'directed',
	'undirected',
	ATTR_LIST,
	"graph { type: undirected; }\n [ A ] --> [ B ]",
     ],

  }, # graph

  edge => {

    style => [
      'The line style of the edge. When set on the general edge class, this attribute changes only the style of all solid edges to the specified one.',
      [ qw/solid dotted dashed dot-dash dot-dot-dash bold bold-dash double-dash double wave broad wide invisible/], # broad-dash wide-dash/ ],
      'solid',
      'dotted',
      undef,
      "[ A ] -- solid --> [ B ]\n .. dotted ..> [ C ]\n -  dashed - > [ D ]\n -- bold --> { style: bold; } [ E ]\n -- broad --> { style: broad; } [ F ]\n -- wide --> { style: wide; } [ G ]",
     ],

    arrowstyle => [
      'The style of the arrow. Open arrows are vee-shaped and the bit inside the arrow has the color of the L<background>. Closed arrows are triangle shaped, with a background-color fill. Filled arrows are closed, too, but use the L<fill> color for the inside. If the fill color is not set, the L<color> attribute will be used instead. An C<arrowstyle> of none creates undirected edges just like "[A] -- [B]" would do.',
      [ qw/none open closed filled/ ],
      'open',
      'closed',
      undef,
      "[ A ] -- open --> [ B ]\n -- closed --> { arrowstyle: closed; } [ C ]\n -- filled --> { arrowstyle: filled; } [ D ]\n -- filled --> { arrowstyle: filled; fill: lime; } [ E ]\n -- none --> { arrowstyle: none; } [ F ]",
     ],

    arrowshape => [
      'The basic shape of the arrow. Can be combined with each of L<arrowstyle>.',
      [ qw/triangle box dot inv line diamond cross x/ ],
      'triangle',
      'box',
      undef,
      "[ A ] -- triangle --> [ B ]\n -- box --> { arrowshape: box; } [ C ]\n" .
      " -- inv --> { arrowshape: inv; } [ D ]\n -- diamond --> { arrowshape: diamond; } [ E ]\n" .
      " -- dot --> { arrowshape: dot; } [ F ]\n" .
      " -- line --> { arrowshape: line; } [ G ] \n" .
      " -- plus --> { arrowshape: cross; } [ H ] \n" .
      " -- x --> { arrowshape: x; } [ I ] \n\n" .
      "[ a ] -- triangle --> { arrowstyle: filled; } [ b ]\n".
      " -- box --> { arrowshape: box; arrowstyle: filled; } [ c ]\n" .
      " -- inv --> { arrowshape: inv; arrowstyle: filled; } [ d ]\n" .
      " -- diamond --> { arrowshape: diamond; arrowstyle: filled; } [ e ]\n" .
      " -- dot --> { arrowshape: dot; arrowstyle: filled; } [ f ]\n" .
      " -- line --> { arrowshape: line; arrowstyle: filled; } [ g ] \n" .
      " -- plus --> { arrowshape: cross; arrowstyle: filled; } [ h ] \n" .
      " -- x --> { arrowshape: x; arrowstyle: filled; } [ i ] \n",
     ],

    labelcolor => [
     'The text color for the label. If unspecified, will fall back to L<color>. See the section about color names and values for reference.',
     undef,
     'black',
     'rgb(255,255,0)',
     ATTR_COLOR,
     "[ Bonn ] -- ICE --> { labelcolor: blue; }\n [ Berlin ]",
     ],

    start => [
     'The starting port of this edge. See <a href="hinting.html#joints">the section about joints</a> for reference.',
     qr/^(south|north|east|west|left|right|front|back)(\s*,\s*-?\d{1,4})?\z/,
     '',
     'front, 0',
     ATTR_PORT,
     "[ Bonn ] -- NORTH --> { start: north; end: north; } [ Berlin ]",
     ],

    end => [
     'The ending port of this edge. See <a href="hinting.html#joints">the section about joints</a> for reference.',
     qr/^(south|north|east|west|right|left|front|back)(\s*,\s*-?\d{1,4})?\z/,
     '',
     'back, 0',
     ATTR_PORT,
     "[ Bonn ] -- NORTH --> { start: south; end: east; } [ Berlin ]",
     ],

    minlen => [
     'The minimum length of the edge, in cells. Defaults to 1. The minimum length is ' .
     'automatically increased for edges with joints.',
     undef,
     '1',
     '4',
     ATTR_UINT,
     "[ Bonn ] -- longer --> { minlen: 3; } [ Berlin ]\n[ Bonn ] --> [ Potsdam ] { origin: Bonn; offset: 2,2; }",
     ],

    autojoin => [
     'Controls whether the layouter can join this edge automatically with other edges leading to the same node. C<never> means this edge will never joined with another edge automatically, C<always> means always (if possible), even if the attributes on the edges do not match. C<equals> means only edges with the same set of attributes will be automatically joined together. See also C<autosplit>.',
     [qw/never always equals/],
     'never',
     'always',
     undef,
     "[ Bonn ], [ Aachen ]\n -- 1 --> { autojoin: equals; } [ Berlin ]",
     ],

    autosplit => [
     'Controls whether the layouter replace multiple edges leading from one node to other nodes with one edge splitting up. C<never> means this edge will never be part of such a split, C<always> means always (if possible), even if the attributes on the edges do not match. C<equals> means only edges with the same set of attributes will be automatically split up. See also C<autojoin>.',
     [qw/never always equals/],
     'never',
     'always',
     undef,
     "[ Bonn ]\n -- 1 --> { autosplit: equals; } [ Berlin ], [ Aachen ]",
     ],

   }, # edge

  group => {
    bordercolor => [
     'The color of the L<border>. See the section about color names and values for reference.',
     undef,
     { default => '#000000' },
     'rgb(255,255,0)',
     ATTR_COLOR,
     "node { border: black bold; }\n[ Black ]\n --> [ Red ]      { bordercolor: red; }\n --> [ Green ]    { bordercolor: green; }",
     ],

    borderstyle => [
     'The style of the L<border>. The special styles "bold", "broad", "wide", "double-dash" and "bold-dash" will set and override the L<borderwidth>.',
     [ qw/none solid dotted dashed dot-dash dot-dot-dash double wave bold bold-dash broad double-dash wide/ ],
     { default => 'none', 'node.anon' => 'none', 'group.anon' => 'none', node => 'solid', group => 'dashed' },
     'dotted',
     undef,
     "node { border: dotted; }\n[ Dotted ]\n --> [ Dashed ]      { borderstyle: dashed; }\n --> [ broad ]    { borderstyle: broad; }",
     ],

    borderwidth => [
     'The width of the L<border>. Certain L<border>-styles will override the width.',
     qr/^\d+(px|em)?\z/,
     '1',
     '2px',
     ],

    border => [
     'The border. Can be any combination of L<borderstyle>, L<bordercolor> and L<borderwidth>.',
     undef,
     { default => 'none', 'node.anon' => 'none', 'group.anon' => 'none', node => 'solid 1px #000000', group => 'dashed 1px #000000' },
     'dotted red',
     undef,
     "[ Normal ]\n --> [ Bold ]      { border: bold; }\n --> [ Broad ]     { border: broad; }\n --> [ Wide ]      { border: wide; }\n --> [ Bold-Dash ] { border: bold-dash; }",
     ],

    nodeclass => [
      'The class into which all nodes of this group are put.',
      qr/^(|[a-zA-Z][a-zA-Z0-9_]*)\z/,
      '',
      'cities',
     ],

    edgeclass => [
      'The class into which all edges defined in this group are put. This includes edges that run between two nodes belonging to the same group.',
      qr/^(|[a-zA-Z][a-zA-Z0-9_]*)\z/,
      '',
      'connections',
     ],

    rank => [
     "The rank of the group, used by the layouter to find the order and placement of group. " .
     "Set to C<auto> (the default), C<same> or a positive number. " .
     "See the section about ranks for reference and more examples.",
       qr/^(auto|same|\d{1,6})\z/,
       'auto',
       'same',
       undef,
     "( Cities: [ Bonn ], [ Berlin ] ) { rank: 0; } ( Rivers: [ Rhein ], [ Sieg ] ) { rank: 0; }",
     ],

    root => [
	"The name of the root node, given as hint to the layouter to start the layout there. When not set, the layouter will pick a node at semi-random.",
	undef,
	'',
	'My Node',
	ATTR_TEXT,
	"( Cities: [ A ] --> [ B ] --> [ C ] --> [ D ] --> [ A ] ) { root: B; }",
     ],

    group => [
     "Puts the group inside this group, nesting the two groups inside each other.",
     undef,
      '',
      'Cities',
       undef,
     "( Cities: [ Bonn ] ) ( Rivers: [ Rhein ] ) { group: Cities:; }",
     ], 

    labelpos => [
	"The position of the group label.",
	[ qw/top bottom/ ],
	'top',
	'bottom',
	ATTR_LIST,
        "group { labelpos: bottom; }\n\n ( My Group: [ Buxtehude ] -> [ Fuchsberg ] )\n"
     ],

   }, # group

  # These entries will be allowed temporarily during Graphviz parsing for
  # intermidiate values, like "shape=record".
  special => { },
  }; # end of attribute definitions

sub _allow_special_attributes
  {
  # store a hash with special temp. attributes
  my ($self, $att) = @_;
  $attributes->{special} = $att;
  }

sub _drop_special_attributes
  {
  # drop the hash with special temp. attributes
  my ($self) = @_;

  $attributes->{special} = {};
  }

sub _attribute_entries
  {
  # for building the manual page
  $attributes;
  }

sub border_attribute
  {
  # Return "1px solid red" from the border-(style|color|width) attributes,
  # mainly used by as_txt() output. Does not use colorscheme!
  my ($self, $class) = @_;

  my ($style,$width,$color);

  my $g = $self; $g = $self->{graph} if ref($self->{graph});

  my ($def_style, $def_color, $def_width);

  # XXX TODO need no_default_attribute()
  if (defined $class)
    {
    $style = $g->attribute($class, 'borderstyle');
    return $style if $style eq 'none';

    $def_style = $g->default_attribute('borderstyle');

    $width = $g->attribute($class,'borderwidth');
    $def_width = $g->default_attribute($class,'borderwidth');
    $width = '' if $def_width eq $width;

    $color = $g->attribute($class,'bordercolor');
    $def_color = $g->default_attribute($class,'bordercolor');
    $color = '' if $def_color eq $color;
    }
  else 
    {
    $style = $self->attribute('borderstyle');
    return $style if $style eq 'none';

    $def_style = $self->default_attribute('borderstyle');

    $width = $self->attribute('borderwidth');
    $def_width = $self->default_attribute('borderwidth');
    $width = '' if $def_width eq $width;

    $color = $self->attribute('bordercolor');
    $def_color = $self->default_attribute('bordercolor');
    $color = '' if $def_color eq $color;
    }

  return '' if $def_style eq $style and $color eq '' && $width eq '';

  Graph::Easy::_border_attribute($style, $width, $color);
  }

sub _unknown_attribute
  {
  # either just warn, or raise an error for unknown attributes
  my ($self, $name, $class) = @_;

  if ($self->{_warn_on_unknown_attributes})
    {
    $self->warn("Ignoring unknown attribute '$name' for class $class") 
    }
  else
    {
    $self->error("Error in attribute: '$name' is not a valid attribute name for a $class");
    }
  return;
  }

sub default_attribute
  {
  # Return the default value for the attribute.
  my ($self, $class, $name) = @_;

  # allow $self->default_attribute('fill');
  if (scalar @_ == 2)
    {
    $name = $class;
    $class = $self->{class} || 'graph';
    }

  # get the base class: node.foo => node
  my $base_class = $class; $base_class =~ s/\..*//;

  # Remap alias names without "-" to their hyphenated version:
  $name = $att_aliases->{$name} if exists $att_aliases->{$name};

  # "x-foo-bar" is a custom attribute, so allow it always. The name must
  # consist only of letters and hyphens, and end in a letter or number.
  # Hyphens must be separated by letters. Custom attributes do not have a default.
  return '' if $name =~ $qr_custom_attribute;

  # prevent ->{special}->{node} from springing into existance
  my $s = $attributes->{special}; $s = $s->{$class} if exists $s->{$class};

  my $entry =	$s->{$name} ||
		$attributes->{all}->{$name} ||
		$attributes->{$base_class}->{$name};

  # Didn't found an entry:
  return $self->_unknown_attribute($name,$class) unless ref($entry);

  # get the default attribute from the entry
  my $def = $entry->[ ATTR_DEFAULT_SLOT ]; my $val = $def;

  # "node.subclass" gets the default from "node", 'edge' from 'default':
  # " { default => 'foo', 'node.anon' => 'none', node => 'solid' }":
  if (ref $def)
    {
    $val = $def->{$class};
    $val = $def->{$base_class} unless defined $val;
    $val = $def->{default} unless defined $val;
    }

  $val;
  }

sub raw_attribute
  {
  # Return either the raw attribute set on an object (honoring inheritance),
  # or undef for when that specific attribute is not set. Does *not*
  # inspect class attributes.
  my ($self, $name) = @_;

  # Remap alias names without "-" to their hyphenated version:
  $name = $att_aliases->{$name} if exists $att_aliases->{$name};

  my $class = $self->{class} || 'graph';
  my $base_class = $class; $base_class =~ s/\..*//;

  # prevent ->{special}->{node} from springing into existance
  my $s = $attributes->{special}; $s = $s->{$class} if exists $s->{$class};

  my $entry =	$s->{$name} ||
		$attributes->{all}->{$name} ||
		$attributes->{$base_class}->{$name};

  # create a fake entry for custom attributes
  $entry = [ '', undef, '', '', ATTR_STRING, '' ]
    if $name =~ $qr_custom_attribute;

  # Didn't found an entry:
  return $self->_unknown_attribute($name,$class) unless ref($entry);

  my $type = $entry->[ ATTR_TYPE_SLOT ] || ATTR_STRING;

  my $val;

  ###########################################################################
  # Check the object directly first
  my $a = $self->{att};
  if (exists $a->{graph})
    {
    # for graphs, look directly in the class to save time:
    $val = $a->{graph}->{$name} 
	if exists $a->{graph}->{$name};
    }
  else
    {
    $val = $a->{$name} if exists $a->{$name};
    }

  # For "background", and objects that are in a group, we inherit "fill":
  $val = $self->{group}->color_attribute('fill')
    if $name eq 'background' && ref $self->{group};

  return $val if !defined $val || $val ne 'inherit' ||
    $name =~ /^x-([a-z_]+-)*[a-z_]+([0-9]*)\z/;

  # $val is defined, and "inherit" (and it is not a special attribute)

  # for graphs, there is nothing to inherit from
  return $val if $class eq 'graph';

  # we try classes in this order:
  # "node", "graph"

  my @tries = ();
  # if the class is already "node", skip it:
  if ($class =~ /\./)
    {
    my $parent_class = $class; $parent_class =~ s/\..*//;
    push @tries, $parent_class;
    }

  # If not part of a graph, we cannot have class attributes, but
  # we still can find default attributes. So fake a "graph":
  my $g = $self->{graph}; 			# for objects in a graph
  $g = { att => {} } unless ref($g);		# for objects not in a graph

  $val = undef;
  for my $try (@tries)
    {
#    print STDERR "# Trying class $try for attribute $name\n";

    my $att = $g->{att}->{$try};

    $val = $att->{$name} if exists $att->{$name};

    # value was not defined, so get the default value
    if (!defined $val)
      {
      my $def = $entry->[ ATTR_DEFAULT_SLOT ]; $val = $def;

      # "node.subclass" gets the default from "node", 'edge' from 'default':
      # " { default => 'foo', 'node.anon' => 'none', node => 'solid' }":
      if (ref $def)
	{
	$val = $def->{$try};
        if (!defined $val && $try =~ /\./)
	  {
	  my $base = $try; $base =~ s/\..*//;
	  $val = $def->{$base};
	  }
	$val = $def->{default} unless defined $val;
	}
      }
    # $val must now be defined, because default value must exist.

#    print STDERR "# Found '$val' for $try\n";

    if ($name ne 'label')
      {
      $self->warn("Uninitialized default for attribute '$name' on class '$try'\n")
        unless defined $val;
      }

    return $val if $type >= ATTR_NO_INHERIT;

    # got some value other than inherit or already at top of tree:
    return $val if defined $val && $val ne 'inherit';
  
    # try next class in inheritance tree
    $val = undef;
    }

  $val;
  }

sub color_attribute
  {
  # Just like get_attribute(), but for colors, and returns them as hex,
  # using the current colorscheme.
  my $self = shift;

  my $color = $self->attribute(@_);

  if ($color !~ /^#/ && $color ne '')
    {
    my $scheme = $self->attribute('colorscheme');
    $color = Graph::Easy->color_as_hex($color, $scheme);
    }

  $color;
  }

sub raw_color_attribute
  {
  # Just like raw_attribute(), but for colors, and returns them as hex,
  # using the current colorscheme.
  my $self = shift;

  my $color = $self->raw_attribute(@_);
  return undef unless defined $color;		# default to undef

  if ($color !~ /^#/ && $color ne '')
    {
    my $scheme = $self->attribute('colorscheme');
    $color = Graph::Easy->color_as_hex($color, $scheme);
    }

  $color;
  }

sub _attribute_entry
  {
  # return the entry defining an attribute, based on the attribute name
  my ($self, $class, $name) = @_;

  # font-size => fontsize
  $name = $att_aliases->{$name} if exists $att_aliases->{$name};

  my $base_class = $class; $base_class =~ s/\.(.*)//;

  # prevent ->{special}->{node} from springing into existance
  my $s = $attributes->{special}; $s = $s->{$class} if exists $s->{$class};
  my $entry =	$s->{$name} ||
		$attributes->{all}->{$name} ||
		$attributes->{$base_class}->{$name};

  $entry;
  }

sub attribute
  {
  my ($self, $class, $name) = @_;

  my $three_arg = 0;
  if (scalar @_ == 3)
    {
    # $self->attribute($class,$name) if only allowed on graphs
    return $self->error("Calling $self->attribute($class,$name) only allowed for graphs") 
      if exists $self->{graph};
  
   if ($class !~ /^(node|group|edge|graph\z)/)
      {
      return $self->error ("Illegal class '$class' when trying to get attribute '$name'");
      }
    $three_arg = 1;
    return $self->border_attribute($class) if $name eq 'border'; # virtual attribute
    }
  else
    {
    # allow calls of the style get_attribute('background');
    $name = $class;
    $class = $self->{class} || 'graph' if $name eq 'class';	# avoid deep recursion
    if ($name ne 'class')
      {
      $class = $self->{cache}->{class};
      $class = $self->class() unless defined $class;
      }

    return $self->border_attribute() if $name eq 'border'; # virtual attribute
    return join (",",$self->size()) if $name eq 'size'; # virtual attribute
    }

#  print STDERR "# called attribute($class,$name)\n";

  # font-size => fontsize
  $name = $att_aliases->{$name} if exists $att_aliases->{$name};
    
  my $base_class = $class; $base_class =~ s/\.(.*)//;
  my $sub_class = $1; $sub_class = '' unless defined $sub_class;
  if ($name eq 'class')
    {
    # "[A] { class: red; }" => "red"
    return $sub_class if $sub_class ne '';
    # "node { class: green; } [A]" => "green": fall through and let the code
    # below look up the attribute or fall back to the default '':
    }

  # prevent ->{special}->{node} from springing into existance
  my $s = $attributes->{special}; $s = $s->{$class} if exists $s->{$class};
  my $entry =	$s->{$name} ||
		$attributes->{all}->{$name} ||
		$attributes->{$base_class}->{$name};

  # create a fake entry for custom attributes
  $entry = [ '', undef, '', '', ATTR_STRING, '' ]
    if $name =~ $qr_custom_attribute;

  # Didn't found an entry:
  return $self->_unknown_attribute($name,$class) unless ref($entry);

  my $type = $entry->[ ATTR_TYPE_SLOT ] || ATTR_STRING;

  my $val;

  if ($three_arg == 0)
    {
    ###########################################################################
    # Check the object directly first
    my $a = $self->{att};
    if (exists $a->{graph})
      {
      # for graphs, look directly in the class to save time:
      $val = $a->{graph}->{$name} 
	if exists $a->{graph}->{$name};
      }
    else
      {
      $val = $a->{$name} if exists $a->{$name};
      }

    # For "background", and objects that are in a group, we inherit "fill":
    if ($name eq 'background' && $val && $val eq 'inherit')
      {
      my $parent = $self->parent();
      $val = $parent->color_attribute('fill') if $parent && $parent != $self;
      }

    # XXX BENCHMARK THIS
    return $val if defined $val && 
	# no inheritance ("inherit" is just a normal string value)
	($type >= ATTR_NO_INHERIT ||
	# no inheritance since value is something else like "red"
	 $val ne 'inherit' ||
	# for graphs, there is nothing to inherit from
	 $class eq 'graph'); 
    }

  # $val not defined, or 'inherit'

  ###########################################################################
  # Check the classes now

#  print STDERR "# Called self->attribute($class,$name) (#2)\n";

  # we try them in this order:
  # node.subclass, node, graph

#  print STDERR "# $self->{name} class=$class ", join(" ", caller),"\n" if $name eq 'align';

  my @tries = ();
  # skip "node.foo" if value is 'inherit'
  push @tries, $class unless defined $val;
  push @tries, $base_class if $class =~ /\./;
  push @tries, 'graph' unless @tries && $tries[-1] eq 'graph';

  # If not part of a graph, we cannot have class attributes, but
  # we still can find default attributes. So fake a "graph":
  my $g = $self->{graph}; 			# for objects in a graph
  $g = { att => {} } unless ref($g);		# for objects not in a graph

  # XXX TODO should not happen
  $g = $self if $self->{class} eq 'graph';	# for the graph itself

  $val = undef;
  TRY:
   for my $try (@tries)
    {
#    print STDERR "# Trying class $try for attribute $name\n" if $name eq 'align';

    my $att = $g->{att}->{$try};

    $val = $att->{$name} if exists $att->{$name};

    # value was not defined, so get the default value (but not for subclasses!)
    if (!defined $val)
      {
      my $def = $entry->[ ATTR_DEFAULT_SLOT ]; $val = $def;

      # "node.subclass" gets the default from "node", 'edge' from 'default':
      # " { default => 'foo', 'node.anon' => 'none', node => 'solid' }":
      if (ref $def)
	{
	$val = $def->{$try};
        if (!defined $val && $try =~ /\./)
	  {
	  my $base = $try; $base =~ s/\..*//;
	  $val = $def->{$base};
	  }
        # if this is not a subclass, get the default value
        next TRY if !defined $val && $try =~ /\./;
        
	$val = $def->{default} unless defined $val;
	}
      }
    # $val must now be defined, because default value must exist.

#    print STDERR "# Found '$val' for $try ($class)\n" if $name eq 'color';

    if ($name ne 'label')
      {
      $self->warn("Uninitialized default for attribute '$name' on class '$try'\n")
        unless defined $val;
      }

    return $val if $type >= ATTR_NO_INHERIT;

    # got some value other than inherit or already at top of tree:
    last if defined $val && ($val ne 'inherit' || $try eq 'graph');

    # try next class in inheritance tree
    $val = undef;
    }

  # For "background", and objects that are in a group, we inherit "fill":
  if ($name eq 'background' && $val && $val eq 'inherit')
    {
    my $parent = $self->parent();
    $val = $parent->color_attribute('fill') if $parent && $parent != $self;
    }

  # If we fell through here, $val is 'inherit' for graph. That happens
  # for instance for 'background':
  $val;
  }

sub unquote_attribute
  {
  # The parser leaves quotes and escapes in the attribute, these things
  # are only removed upon storing the attribute at the object/class.
  # Return the attribute unquoted (remove quotes on labels, links etc).
  my ($self,$class,$name,$val) = @_;

  # clean quoted strings
  # XXX TODO
  # $val =~ s/^["'](.*[^\\])["']\z/$1/;
  $val =~ s/^["'](.*)["']\z/$1/;

  $val =~ s/\\([#"';\\])/$1/g;		# reverse backslashed chars

  # remove any %00-%1f, %7f and high-bit chars to avoid exploits and problems
  $val =~ s/%[^2-7][a-fA-F0-9]|%7f//g;

  # decode %XX entities
  $val =~ s/%([2-7][a-fA-F0-9])/sprintf("%c",hex($1))/eg;

  $val;
  }

sub valid_attribute
  {
  # Only for compatibility, use validate_attribute()!

  # Check that an name/value pair is an valid attribute, returns:
  # scalar value:	valid, new attribute
  # undef:	 	not valid
  # []:			unknown attribute (might also warn)
  my ($self, $name, $value, $class) = @_;

  my ($error,$newname,$v) = $self->validate_attribute($name,$value,$class);

  return [] if defined $error && $error == 1;
  return undef if defined $error && $error == 2;
  $v;
  }

sub validate_attribute
  {
  # Check that an name/value pair is an valid attribute, returns:
  # $error, $newname, @values

  # A possible new name is in $newname, this is f.i. used to convert
  # "font-size" # to "fontsize".

  # Upon errors, $error contains the error code:
  # undef:	 	all went well
  # 1			unknown attribute name
  # 2			invalid attribute value 
  # 4			found multiple attributes, but these aren't
  #			allowed at this place

  my ($self, $name, $value, $class, $no_multiples) = @_;

  $self->error("Got reference $value as value, but expected scalar") if ref($value);
  $self->error("Got reference $name as name, but expected scalar") if ref($name);

  # "x-foo-bar" is a custom attribute, so allow it always. The name must
  # consist only of letters and hyphens, and end in a letter. Hyphens
  # must be separated by letters.
  return (undef, $name, $value) if $name =~ $qr_custom_attribute;

  $class = 'all' unless defined $class;
  $class =~ s/\..*\z//;		# remove subclasses

  # Remap alias names without "-" to their hyphenated version:
  $name = $att_aliases->{$name} if exists $att_aliases->{$name};

  # prevent ->{special}->{node} from springing into existance
  my $s = $attributes->{special}; $s = $s->{$class} if exists $s->{$class};

  my $entry = $s->{$name} ||
	      $attributes->{all}->{$name} || $attributes->{$class}->{$name};

  # Didn't found an entry:
  return (1,undef,$self->_unknown_attribute($name,$class)) unless ref($entry);

  my $check = $entry->[ATTR_MATCH_SLOT];
  my $type = $entry->[ATTR_TYPE_SLOT] || ATTR_STRING;

  $check = '_color' if $type == ATTR_COLOR;
  $check = '_angle' if $type == ATTR_ANGLE;
  $check = '_uint' if $type == ATTR_UINT;

  my @values = ($value);

  # split on "|", but not on "\|"
  # XXX TODO:
  # This will not work in case of mixed " $i \|\| 0| $a = 1;"

  # When special attributes are set, we are parsing Graphviz, and do
  # not allow/use multiple attributes. So skip the split.
  if (keys %{$attributes->{special}} == 0)
     {
     @values = split (/\s*\|\s*/, $value, -1) if $value =~ /(^|[^\\])\|/;
     }

  my $multiples = 0; $multiples = 1 if @values > 1;
  return (4) if $no_multiples && $multiples; 		# | and no multiples => error

  # check each part on it's own
  my @rc;
  for my $v (@values)
    {
    # don't check empty parts for being valid
    push @rc, undef and next if $multiples && $v eq '';

    if (defined $check && !ref($check))
      {
      no strict 'refs';
      my $checked = $self->$check($v, $name);
      if (!defined $checked)
	{
        $self->error("Error in attribute: '$v' is not a valid $name for a $class");
        return (2);
        }
      push @rc, $checked;
      }
    elsif ($check)
      {
      if (ref($check) eq 'ARRAY')
        {
        # build a regexp from the list of words
        my $list = 'qr/^(' . join ('|', @$check) . ')\z/;';
        $entry->[1] = eval($list);
        $check = $entry->[1];
        }
      if ($v !~ $check)				# invalid?
	{
        $self->error("Error in attribute: '$v' is not a valid $name for a $class");
	return (2);
	}

      push @rc, $v;				# valid
      }
    # entry found, but no specific check => anything goes as value
    else { push @rc, $v; }

    # "ClAss" => "class" for LCTEXT entries
    $rc[-1] = lc($rc[-1]) if $type == ATTR_LCTEXT;
    }

  # only one value ('green')
  return (undef, $name, $rc[0]) unless $multiples;

  # multiple values ('green|red')
  (undef, $name, \@rc);
  }

###########################################################################
###########################################################################

sub _remap_attributes
  {
  # Take a hash with:
  # {
  #   class => {
  #     color => 'red'
  #   }
  # }
  # and remap it according to the given remap hash (similiar structured).
  # Also encode/quote the value. Suppresses default attributes.
  my ($self, $object, $att, $remap, $noquote, $encode, $color_remap ) = @_;

  my $out = {};

  my $class = $object || 'node';
  $class = $object->{class} || 'graph' if ref($object);
  $class =~ s/\..*//;				# remove subclass

  my $r = $remap->{$class};
  my $ra = $remap->{all};
  my $ral = $remap->{always};
  my $x = $remap->{x};

  # This loop does also handle the individual "bordercolor" attributes.
  # If the output should contain only "border", but not "bordercolor", then
  # the caller must filter them out.

  # do these attributes
  my @keys = keys %$att;

  my $color_scheme = 'w3c';
  $color_scheme = $object->attribute('colorscheme') if ref($object);
  $color_scheme = $self->get_attribute($object,'colorscheme')
    if defined $object && !ref($object);

  $color_scheme = $self->get_attribute('graph','colorscheme')
    if defined $color_scheme && $color_scheme eq 'inherit';

  for my $atr (@keys)
    {
    my $val = $att->{$atr};

    # Only for objects (not for classes like "node"), and not if
    # always says we need to always call the CODE handler:

    if (!ref($object) && !exists $ral->{$atr})
      {
      # attribute not defined
      next if !defined $val || $val eq '' ||
      # or $remap says we should suppress it
         (exists $r->{$atr} && !defined $r->{$atr}) ||
         (exists $ra->{$atr} && !defined $ra->{$atr});
      }

    my $entry = $attributes->{all}->{$atr} || $attributes->{$class}->{$atr};

    if ($color_remap && defined $entry && defined $val)
      {
      # look up whether attribute is a color
      # if yes, convert to hex
      $val = $self->color_as_hex($val,$color_scheme)
        if ($entry->[ ATTR_TYPE_SLOT ]||ATTR_STRING) == ATTR_COLOR;
      }

    my $temp = { $atr => $val };

    # see if there is a handler for custom attributes
    if (exists $r->{$atr} || exists $ra->{$atr} || (defined $x && $atr =~ /^x-/))
      {
      my $rc = $r->{$atr}; $rc = $ra->{$atr} unless defined $rc;
      $rc = $x unless defined $rc;

      # if given a code ref, call it to remap name and/or value
      if (ref($rc) eq 'CODE')
        {
        my @rc = &{$rc}($self,$atr,$val,$object);
        $temp = {};
        while (@rc)
          {
          my $a = shift @rc; my $v = shift @rc;
          $temp->{ $a } = $v if defined $a && defined $v;
          }
        }
      else
        {
        # otherwise, rename the attribute name if nec.
        $temp = { };
        $temp = { $rc => $val } if defined $val && defined $rc;
        }
      }

    for my $at (keys %$temp)
      {
      my $v = $temp->{$at};

      next if !defined $at || !defined $v || $v eq '';

      # encode critical characters (including "), but only if the value actually
      # contains anything else than '%' (so rgb(10%,0,0) stays as it is)

      $v =~ s/([;"%\x00-\x1f])/sprintf("%%%02x",ord($1))/eg 
        if $encode && $v =~ /[;"\x00-\x1f]/;
      # quote if nec.
      $v = '"' . $v . '"' unless $noquote;

      $out->{$at} = $v;
      }
    }

  $out;
  }

sub raw_attributes
  {
  # return all set attributes on this object (graph/node/group/edge) as
  # an anonymous hash ref
  my $self = shift;

  my $class = $self->{class} || 'graph';

  my $att = $self->{att};
  $att = $self->{att}->{graph} if $class eq 'graph';

  my $g = $self->{graph} || $self;

  my $out = {};
  if (!$g->{strict})
    {
    for my $name (keys %$att)
      {
      my $val = $att->{$name};
      next unless defined $val;			# set to undef?

      $out->{$name} = $val;
      }
    return $out;
    }

  my $base_class = $class; $base_class =~ s/\..*//;
  for my $name (keys %$att)
    {
    my $val = $att->{$name};
    next unless defined $val;			# set to undef?

    $out->{$name} = $val;
 
    next unless $val eq 'inherit';
 
    # prevent ->{special}->{node} from springing into existance
    my $s = $attributes->{special}; $s = $s->{$class} if exists $s->{$class};
    my $entry =	$s->{$name} ||
		$attributes->{all}->{$name} ||
		$attributes->{$base_class}->{$name};

    # Didn't found an entry:
    return $self->_unknown_attribute($name,$class) unless ref($entry);
  
    my $type = $entry->[ ATTR_TYPE_SLOT ] || ATTR_STRING;

    # need to inherit value?
    $out->{$name} = $self->attribute($name) if $type < ATTR_NO_INHERIT;
    }

  $out;
  }

sub get_attributes
  {
  # Return all effective attributes on this object (graph/node/group/edge) as
  # an anonymous hash ref. This respects inheritance and default values.
  # Does not return custom attributes, see get_custom_attributes().
  my $self = shift;

  $self->error("get_attributes() doesn't take arguments") if @_ > 0;

  my $att = {};
  my $class = $self->main_class();

  # f.i. "all", "node"
  for my $type ('all', $class)
    {
    for my $a (keys %{$attributes->{$type}})
      {
      my $val = $self->attribute($a);		# respect inheritance	
      $att->{$a} = $val if defined $val;
      }
    }

  $att;
  }

package Graph::Easy::Node;

BEGIN
  {
  *custom_attributes = \&get_custom_attributes;
  }

sub get_custom_attributes
  {
  # Return all custom attributes on this object (graph/node/group/edge) as
  # an anonymous hash ref.
  my $self = shift;

  $self->error("get_custom_attributes() doesn't take arguments") if @_ > 0;

  my $att = {};

  for my $key (keys %{$self->{att}})
    {
    $att->{$key} = $self->{att}->{$key};
    }

  $att;
  }

1;
__END__

=head1 NAME

Graph::Easy::Attributes - Define and check attributes for Graph::Easy

=head1 SYNOPSIS

	use Graph::Easy;

	my $graph = Graph::Easy->new();

	my $hexred = Graph::Easy->color_as_hex( 'red' );
	my ($name, $value) = $graph->valid_attribute( 'color', 'red', 'graph' );
	print "$name => $value\n" if !ref($value);

=head1 DESCRIPTION

C<Graph::Easy::Attributes> contains the definitions of valid attribute names
and values for L<Graph::Easy|Graph::Easy>. It is used by both the parser
and by Graph::Easy to check attributes for being valid and well-formed. 

There should be no need to use this module directly.

For a complete list of attributes and their possible values, please see
L<Graph::Easy::Manual>.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2008 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut
#############################################################################
# Represents one node in a Graph::Easy graph.
#
# (c) by Tels 2004-2008. Part of Graph::Easy.
#############################################################################

package Graph::Easy::Node;

$VERSION = '0.38';

use Graph::Easy::Base;
use Graph::Easy::Attributes;
@ISA = qw/Graph::Easy::Base/;

# to map "arrow-shape" to "arrowshape"
my $att_aliases;

use strict;
use constant isa_cell => 0;

sub _init
  {
  # Generic init routine, to be overridden in subclasses.
  my ($self,$args) = @_;
  
  $self->{name} = 'Node #' . $self->{id};
  
  $self->{att} = { };
  $self->{class} = 'node';		# default class

  foreach my $k (keys %$args)
    {
    if ($k !~ /^(label|name)\z/)
      {
      require Carp;
      Carp::confess ("Invalid argument '$k' passed to Graph::Easy::Node->new()");
      }
    $self->{$k} = $args->{$k} if $k eq 'name';
    $self->{att}->{$k} = $args->{$k} if $k eq 'label';
    }

  # These are undef (to save memory) until needed: 
  #  $self->{children} = {};
  #  $self->{dx} = 0;		# relative to no other node
  #  $self->{dy} = 0;
  #  $self->{origin} = undef;	# parent node (for relative placement)
  #  $self->{group} = undef;
  #  $self->{parent} = $graph or $group;
  # Mark as not yet laid out: 
  #  $self->{x} = 0;
  #  $self->{y} = 0;
  
  $self;
  }

my $merged_borders = 
  {
    'dotteddashed' => 'dot-dash',
    'dasheddotted' => 'dot-dash',
    'double-dashdouble' => 'double',
    'doubledouble-dash' => 'double',
    'doublesolid' => 'double',
    'soliddouble' => 'double',
    'dotteddot-dash' => 'dot-dash',
    'dot-dashdotted' => 'dot-dash',
  };

sub _collapse_borders
  {
  # Given a right border from node one, and the left border of node two,
  # return what border we need to draw on node two:
  my ($self, $one, $two, $swapem) = @_;

  ($one,$two) = ($two,$one) if $swapem;

  $one = 'none' unless $one;
  $two = 'none' unless $two;

  # If the border of the left/top node is defined, we don't draw the
  # border of the right/bottom node.
  return 'none' if $one ne 'none' || $two ne 'none';

  # otherwise, we draw simple the right border
  $two;
  }

sub _merge_borders
  {
  my ($self, $one, $two) = @_;

  $one = 'none' unless $one;
  $two = 'none' unless $two;
  
  # "nonenone" => "none" or "dotteddotted" => "dotted"
  return $one if $one eq $two;

  # none + solid == solid + none == solid
  return $one if $two eq 'none';
  return $two if $one eq 'none';

  for my $b (qw/broad wide bold double solid/)
    {
    # the stronger one overrides the weaker one
    return $b if $one eq $b || $two eq $b;
    }

  my $both = $one . $two;
  return $merged_borders->{$both} if exists $merged_borders->{$both};

  # fallback
  $two;
  }

sub _border_to_draw
  {
  # Return the border style we need to draw, taking the shape (none) into
  # account
  my ($self, $shape) = @_;

  my $cache = $self->{cache};

  return $cache->{border_style} if defined $cache->{border_style};

  $shape = $self->{att}->{shape} unless defined $shape;
  $shape = $self->attribute('shape') unless defined $shape;

  $cache->{border_style} = $self->{att}->{borderstyle};
  $cache->{border_style} = $self->attribute('borderstyle') unless defined $cache->{border_style};
  $cache->{border_style} = 'none' if $shape =~ /^(none|invisible)\z/;
  $cache->{border_style};
  }

sub _border_styles
  {
  # Return the four border styles (right, bottom, left, top). This takes
  # into account the neighbouring nodes and their borders, so that on
  # ASCII output the borders can be properly collapsed.
  my ($self, $border, $collapse) = @_;

  my $cache = $self->{cache};

  # already computed values?
  return if defined $cache->{left_border};

  $cache->{left_border} = $border; 
  $cache->{top_border} = $border;
  $cache->{right_border} = $border; 
  $cache->{bottom_border} = $border;

  return unless $collapse;

#  print STDERR " border_styles: $self->{name} border=$border\n";

  my $EM = 14;
  my $border_width = Graph::Easy::_border_width_in_pixels($self,$EM);

  # convert overly broad borders to the correct style
  $border = 'bold' if $border_width > 2;
  $border = 'broad' if $border_width > $EM * 0.2 && $border_width < $EM * 0.75;
  $border = 'wide' if $border_width >= $EM * 0.75;

#  XXX TODO
#  handle different colors, too:
#  my $color = $self->color_attribute('bordercolor');

  # Draw border on A (left), and C (left):
  #
  #    +---+
  #  B | A | C 
  #    +---+

  # Ditto, plus C's border:
  #
  #    +---+---+
  #  B | A | C |
  #    +---+---+
  #

  # If no left neighbour, draw border normally

  # XXX TODO: ->{parent} ?
  my $parent = $self->{parent} || $self->{graph};
  return unless ref $parent;

  my $cells = $parent->{cells};
  return unless ref $cells;

  my $x = $self->{x}; my $y = $self->{y};

  $x -= 1; my $left = $cells->{"$x,$y"};
  $x += 1; $y-= 1; my $top = $cells->{"$x,$y"};
  $x += 1; $y += 1; my $right = $cells->{"$x,$y"};
  $x -= 1; $y += 1; my $bottom = $cells->{"$x,$y"};

  # where to store the result
  my @where = ('left', 'top', 'right', 'bottom');
  # need to swap arguments to _collapse_borders()?
  my @swapem = (0, 0, 1, 1);
 
  for my $other ($left, $top, $right, $bottom)
    {
    my $side = shift @where;
    my $swap = shift @swapem;
  
    # see if we have a (visible) neighbour on the left side
    if (ref($other) && 
      !$other->isa('Graph::Easy::Edge') &&
      !$other->isa_cell() &&
      !$other->isa('Graph::Easy::Node::Empty'))
      {
      $other = $other->{node} if ref($other->{node});

#      print STDERR "$side node $other ", $other->_border_to_draw(), " vs. $border (swap $swap)\n";

      if ($other->attribute('shape') ne 'invisible')
        {
        # yes, so take its border style
        my $result;
        if ($swap)
	  {
          $result = $self->_merge_borders($other->_border_to_draw(), $border);
	  }
        else
	  {
	  $result = $self->_collapse_borders($border, $other->_border_to_draw());
	  }
        $cache->{$side . '_border'} = $result;

#	print STDERR "# result: $result\n";
        }
      }
    }
  }

sub _correct_size
  {
  # Correct {w} and {h} after parsing. This is a fallback in case
  # the output specific routines (_correct_site_ascii() etc) do
  # not exist.
  my $self = shift;

  return if defined $self->{w};

  my $shape = $self->attribute('shape');

  if ($shape eq 'point')
    {
    $self->{w} = 5;
    $self->{h} = 3;
    my $style = $self->attribute('pointstyle');
    my $shape = $self->attribute('pointshape');
    if ($style eq 'invisible' || $shape eq 'invisible')
      {
      $self->{w} = 0; $self->{h} = 0; return; 
      }
    }
  elsif ($shape eq 'invisible')
    {
    $self->{w} = 3;
    $self->{h} = 3;
    }
  else
    {
    my ($w,$h) = $self->dimensions();
    $self->{h} = $h;
    $self->{w} = $w + 2;
    }

  my $border = $self->_border_to_draw($shape);

  $self->_border_styles($border, 'collapse');

#  print STDERR "# $self->{name} $self->{w} $self->{h} $shape\n";
#  use Data::Dumper; print Dumper($self->{cache});

  if ($shape !~ /^(invisible|point)/)
    {
    $self->{w} ++ if $self->{cache}->{right_border} ne 'none';
    $self->{w} ++ if $self->{cache}->{left_border} ne 'none';
    $self->{h} ++ if $self->{cache}->{top_border} ne 'none';
    $self->{h} ++ if $self->{cache}->{bottom_border} ne 'none';

    $self->{h} += 2 if $border eq 'none' && $shape !~ /^(invisible|point)/;
    }

  $self;
  }

sub _unplace
  {
  # free the cells this node occupies from $cells
  my ($self,$cells) = @_;

  my $x = $self->{x}; my $y = $self->{y};
  delete $cells->{"$x,$y"};
  $self->{x} = undef;
  $self->{y} = undef;
  $self->{cache} = {};

  $self->_calc_size() unless defined $self->{cx};

  if ($self->{cx} + $self->{cy} > 2)	# one of them > 1!
    {
    for my $ax (1..$self->{cx})
      {
      my $sx = $x + $ax - 1;
      for my $ay (1..$self->{cy})
        {
        my $sy = $y + $ay - 1;
        # free cell
        delete $cells->{"$sx,$sy"};
        }
      }
    } # end handling multi-celled node

  # unplace all edges leading to/from this node, too:
  for my $e (values %{$self->{edges}})
    {
    $e->_unplace($cells);
    }

  $self;
  }

sub _mark_as_placed
  {
  # for creating an action on the action stack we also need to recursively
  # mark all our children as already placed:
  my ($self) = @_;

  no warnings 'recursion';

  delete $self->{_todo};

  for my $child (values %{$self->{children}})
    {
    $child->_mark_as_placed();
    }
  $self;
  }

sub _place_children
  {
  # recursively place node and its children
  my ($self, $x, $y, $parent) = @_;

  no warnings 'recursion';

  return 0 unless $self->_check_place($x,$y,$parent);

  print STDERR "# placing children of $self->{name} based on $x,$y\n" if $self->{debug};

  for my $child (values %{$self->{children}})
    {
    # compute place of children (depending on whether we are multicelled or not)

    my $dx = $child->{dx} > 0 ? $self->{cx} - 1 : 0;
    my $dy = $child->{dy} > 0 ? $self->{cy} - 1 : 0;

    my $rc = $child->_place_children($x + $dx + $child->{dx},$y + $dy + $child->{dy},$parent);
    return $rc if $rc == 0;
    }
  $self->_place($x,$y,$parent);
  }

sub _place
  {
  # place this node at the requested position (without checking)
  my ($self, $x, $y, $parent) = @_;

  my $cells = $parent->{cells};
  $self->{x} = $x;
  $self->{y} = $y;
  $cells->{"$x,$y"} = $self;

  # store our position if we are the first node in that rank
  my $r = abs($self->{rank} || 0);
  my $what = $parent->{_rank_coord} || 'x';	# 'x' or 'y'
  $parent->{_rank_pos}->{ $r } = $self->{$what} 
    unless defined $parent->{_rank_pos}->{ $r };

  # a multi-celled node will be stored like this:
  # [ node   ] [ filler ]
  # [ filler ] [ filler ]
  # [ filler ] [ filler ] etc.

#  $self->_calc_size() unless defined $self->{cx};

  if ($self->{cx} + $self->{cy} > 2)    # one of them > 1!
    {
    for my $ax (1..$self->{cx})
      {
      my $sx = $x + $ax - 1;
      for my $ay (1..$self->{cy})
        {
        next if $ax == 1 && $ay == 1;   # skip left-upper most cell
        my $sy = $y + $ay - 1;

        # We might even get away with creating only one filler cell
        # although then its "x" and "y" values would be "wrong".

        my $filler = 
	  Graph::Easy::Node::Cell->new ( node => $self, x => $sx, y => $sy );
        $cells->{"$sx,$sy"} = $filler;
        }
      }
    } # end handling of multi-celled node

  $self->_update_boundaries($parent);

  1;					# did place us
  } 

sub _check_place
  {
  # chack that a node can be placed at $x,$y (w/o checking its children)
  my ($self,$x,$y,$parent) = @_;

  my $cells = $parent->{cells};

  # node cannot be placed here
  return 0 if exists $cells->{"$x,$y"};

  $self->_calc_size() unless defined $self->{cx};

  if ($self->{cx} + $self->{cy} > 2)	# one of them > 1!
    {
    for my $ax (1..$self->{cx})
      {
      my $sx = $x + $ax - 1;
      for my $ay (1..$self->{cy})
        {
        my $sy = $y + $ay - 1;
        # node cannot be placed here
        return 0 if exists $cells->{"$sx,$sy"};
        }
      }
    }
  1;					# can place it here
  }

sub _do_place
  {
  # Tries to place the node at position ($x,$y) by checking that
  # $cells->{"$x,$y"} is still free. If the node belongs to a cluster,
  # checks all nodes of the cluster (and when all of them can be
  # placed simultanously, does so).
  # Returns true if the operation succeeded, otherwise false.
  my ($self,$x,$y,$parent) = @_;

  my $cells = $parent->{cells};

  # inlined from _check() for speed reasons:

  # node cannot be placed here
  return 0 if exists $cells->{"$x,$y"};

  $self->_calc_size() unless defined $self->{cx};

  if ($self->{cx} + $self->{cy} > 2)	# one of them > 1!
    {
    for my $ax (1..$self->{cx})
      {
      my $sx = $x + $ax - 1;
      for my $ay (1..$self->{cy})
        {
        my $sy = $y + $ay - 1;
        # node cannot be placed here
        return 0 if exists $cells->{"$sx,$sy"};
        }
      }
    }

  my $children = 0;
  $children = scalar keys %{$self->{children}} if $self->{children};

  # relativ to another, or has children (relativ to us)
  if (defined $self->{origin} || $children > 0)
    {
    # The coordinates of the origin node. Because 'dx' and 'dy' give
    # our distance from the origin, we can compute the origin by doing
    # "$x - $dx"

    my $grandpa = $self; my $ox = 0; my $oy = 0;
    # Find our grandparent (e.g. the root of origin chain), and the distance
    # from $x,$y to it:
    ($grandpa,$ox,$oy) = $self->find_grandparent() if $self->{origin};

    # Traverse all children and check their places, place them if poss.
    # This will also place ourselves, because we are a grandchild of $grandpa
    return $grandpa->_place_children($x + $ox,$y + $oy,$parent);
    }

  # finally place this node at the requested position
  $self->_place($x,$y,$parent);
  }

#############################################################################

sub _wrapped_label
  {
  # returns the label wrapped automatically to use the least space
  my ($self, $label, $align, $wrap) = @_;

  return (@{$self->{cache}->{label}}) if $self->{cache}->{label};

  # XXX TODO: handle "paragraphs"
  $label =~ s/\\(n|r|l|c)/ /g;		# replace line splits by spaces

  # collapse multiple spaces
  $label =~ s/\s+/ /g;

  # find out where to wrap
  if ($wrap eq 'auto')
    {
    $wrap = int(sqrt(length($label)) * 1.4);
    }
  $wrap = 2 if $wrap < 2;

  # run through the text and insert linebreaks
  my $i = 0;
  my $line_len = 0;
  my $last_space = 0;
  my $last_hyphen = 0;
  my @lines;
  while ($i < length($label))
    {
    my $c = substr($label,$i,1);
    $last_space = $i if $c eq ' ';
    $last_hyphen = $i if $c eq '-';
    $line_len ++;
    if ($line_len >= $wrap && ($last_space != 0 || $last_hyphen != 0))
      {
#      print STDERR "# wrap at $line_len\n";

      my $w = $last_space; my $replace = '';
      if ($last_hyphen > $last_space)
	{
        $w = $last_hyphen; $replace = '-';
	}

#      print STDERR "# wrap at $w\n";

      # "foo bar-baz" => "foo bar" (lines[0]) and "baz" (label afterwards)

#      print STDERR "# first part '". substr($label, 0, $w) . "'\n";

      push @lines, substr($label, 0, $w) . $replace;
      substr($label, 0, $w+1) = '';
      # reset counters
      $line_len = 0;
      $i = 0;
      $last_space = 0;
      $last_hyphen = 0;
      next;
      }
    $i++;
    }
  # handle what is left over
  push @lines, $label if $label ne '';

  # generate the align array
  my @aligns;
  my $al = substr($align,0,1); 
  for my $i (0.. scalar @lines)
    {
    push @aligns, $al; 
    }
  # cache the result to avoid costly recomputation
  $self->{cache}->{label} = [ \@lines, \@aligns ];
  (\@lines, \@aligns);
  }

sub _aligned_label
  {
  # returns the label lines and for each one the alignment l/r/c
  my ($self, $align, $wrap) = @_;

  $align = 'center' unless $align;
  $wrap = $self->attribute('textwrap') unless defined $wrap;

  my $name = $self->label();

  return $self->_wrapped_label($name,$align,$wrap) unless $wrap eq 'none';

  my (@lines,@aligns);
  my $al = substr($align,0,1);
  my $last_align = $al;

  # split up each line from the front
  while ($name ne '')
    {
    $name =~ s/^(.*?([^\\]|))(\z|\\(n|r|l|c))//;
    my $part = $1;
    my $a = $3 || '\n';

    $part =~ s/\\\|/\|/g;		# \| => |
    $part =~ s/\\\\/\\/g;		# '\\' to '\'
    $part =~ s/^\s+//;			# remove spaces at front
    $part =~ s/\s+\z//;			# remove spaces at end
    $a =~ s/\\//;			# \n => n
    $a = $al if $a eq 'n';
    
    push @lines, $part;
    push @aligns, $last_align;

    $last_align = $a;
    }

  # XXX TODO: should remove empty lines at start/end?
  (\@lines, \@aligns);
  }

#############################################################################
# as_html conversion and helper functions related to that

my $remap = {
  node => {
    align => undef,
    background => undef,
    basename => undef,
    border => undef,
    borderstyle => undef,
    borderwidth => undef,
    bordercolor => undef,
    columns => undef,
    fill => 'background',
    origin => undef,
    offset => undef, 
    pointstyle => undef,
    pointshape => undef,
    rows => undef, 
    size => undef,
    shape => undef,
    },
  edge => {
    fill => undef,
    border => undef,
    },
  all => {
    align => 'text-align',
    autolink => undef,
    autotitle => undef,
    comment => undef,
    fontsize => undef,
    font => 'font-family',
    flow => undef,
    format => undef,
    label => undef,
    link => undef,
    linkbase => undef,
    style => undef,
    textstyle => undef,
    title => undef,
    textwrap => \&Graph::Easy::_remap_text_wrap,
    group => undef,
    },
  };

sub _extra_params
  {
  # return text with a leading " ", that will be appended to "td" when
  # generating HTML
  '';
  }

# XXX TODO: <span class="o">?
my $pod = {
  B => [ '<b>', '</b>' ],
  O => [ '<span style="text-decoration: overline">', '</span>' ],
  S => [ '<span style="text-decoration: line-through">', '</span>' ],
  U => [ '<span style="text-decoration: underline">', '</span>' ],
  C => [ '<code>', '</code>' ],
  I => [ '<i>', '</i>' ],
  };

sub _convert_pod
  {
  my ($self, $type, $text) = @_;

  my $t = $pod->{$type} or return $text;

  # "<b>" . "text" . "</b>"
  $t->[0] . $text . $t->[1];
  }

sub _label_as_html
  {
  # Build the text from the lines, by inserting <b> for each break
  # Also align each line, and if nec., convert B<bold> to <b>bold</b>.
  my ($self) = @_;

  my $align = $self->attribute('align');
  my $text_wrap = $self->attribute('textwrap');

  my ($lines,$aligns);
  if ($text_wrap eq 'auto')
    {
    # set "white-space: nowrap;" in CSS and ignore linebreaks in label
    $lines = [ $self->label() ];
    $aligns = [ substr($align,0,1) ];
    }
  else
    {
    ($lines,$aligns) = $self->_aligned_label($align,$text_wrap);
    }

  # Since there is no "float: center;" in CSS, we must set the general
  # text-align to center when we encounter any \c and the default is
  # left or right:

  my $switch_to_center = 0;
  if ($align ne 'center')
    {
    local $_;
    $switch_to_center = grep /^c/, @$aligns;
    }

  $align = 'center' if $switch_to_center;
  my $a = substr($align,0,1);			# center => c

  my $format = $self->attribute('format');

  my $name = '';
  my $i = 0;
  while ($i < @$lines)
    {
    my $line = $lines->[$i];
    my $al = $aligns->[$i];

    # This code below will not handle B<bold\n and bolder> due to the
    # line break. Also, nesting does not work due to returned "<" and ">".

    if ($format eq 'pod')
      {
      # first inner-most, then go outer until there are none left
      $line =~ s/([BOSUCI])<([^<>]+)>/ $self->_convert_pod($1,$2);/eg
        while ($line =~ /[BOSUCI]<[^<>]+>/)
      }
    else
      { 
      $line =~ s/&/&amp;/g;			# quote &
      $line =~ s/>/&gt;/g;			# quote >
      $line =~ s/</&lt;/g;			# quote <
      $line =~ s/\\\\/\\/g;			# "\\" to "\"
      }

    # insert a span to align the line unless the default already covers it
    $line = '<span class="' . $al . '">' . $line . '</span>'
      if $a ne $al;
    $name .= '<br>' . $line;

    $i++;					# next line
    }
  $name =~ s/^<br>//;				# remove first <br> 

  ($name, $switch_to_center);
  }

sub quoted_comment
  {
  # Comment of this object, quoted suitable as to be embedded into HTML/SVG
  my $self = shift;

  my $cmt = $self->attribute('comment');
  if ($cmt ne '')
    {
    $cmt =~ s/&/&amp;/g;
    $cmt =~ s/</&lt;/g;
    $cmt =~ s/>/&gt;/g;
    $cmt = '<!-- ' . $cmt . " -->\n";
    }

  $cmt;
  }

sub as_html
  {
  # return node as HTML
  my ($self) = @_;

  my $shape = 'rect';
  $shape = $self->attribute('shape') unless $self->isa_cell();

  if ($shape eq 'edge')
    {
    my $edge = Graph::Easy::Edge->new();
    my $cell = Graph::Easy::Edge::Cell->new( edge => $edge );
    $cell->{w} = $self->{w};
    $cell->{h} = $self->{h};
    $cell->{att}->{label} = $self->label();
    $cell->{type} =
     Graph::Easy::Edge::Cell->EDGE_HOR +
     Graph::Easy::Edge::Cell->EDGE_LABEL_CELL;
    return $cell->as_html();
    }

  my $extra = $self->_extra_params();
  my $taga = "td$extra";
  my $tagb = 'td';

  my $id = $self->{graph}->{id};
  my $a = $self->{att};
  my $g = $self->{graph};

  my $class = $self->class();

  # how many rows/columns will this node span?
  my $rs = ($self->{cy} || 1) * 4;
  my $cs = ($self->{cx} || 1) * 4;

  # shape: invisible; must result in an empty cell
  if ($shape eq 'invisible' && $class ne 'node.anon')
    {
    return " <$taga colspan=$cs rowspan=$rs style=\"border: none; background: inherit;\"></$tagb>\n";
    }

  my $c = $class; $c =~ s/\./_/g;	# node.city => node_city

  my $html = " <$taga colspan=$cs rowspan=$rs##class####style##";
   
  my $title = $self->title();
  $title =~ s/'/&#27;/g;			# replace quotation marks

  $html .= " title='$title'" if $title ne '' && $shape ne 'img';	# add mouse-over title

  my ($name, $switch_to_center);

  if ($shape eq 'point')
    {
    require Graph::Easy::As_ascii;		# for _u8 and point-style

    local $self->{graph}->{_ascii_style} = 1;	# use utf-8
    $name = $self->_point_style( $self->attribute('pointshape'), $self->attribute('pointstyle') );
    }
  elsif ($shape eq 'img')
    {
    # take the label as the URL, but escape critical characters
    $name = $self->label();
    $name =~ s/\s/\+/g;				# space
    $name =~ s/'/%27/g;				# replace quotation marks
    $name =~ s/[\x0d\x0a]//g;			# remove 0x0d0x0a and similiar
    my $t = $title; $t = $name if $t eq ''; 
    $name = "<img src='$name' alt='$t' title='$t' border='0' />";
    }
  else
    {
    ($name,$switch_to_center) = $self->_label_as_html(); 
    }

  # if the label is "", the link wouldn't be clickable
  my $link = ''; $link = $self->link() unless $name eq '';

  # the attributes in $out will be applied to either the TD, or the inner DIV,
  # unless if we have a link, then most of them will be moved to the A HREF
  my $att = $self->raw_attributes();
  my $out = $self->{graph}->_remap_attributes( $self, $att, $remap, 'noquote', 'encode', 'remap_colors');

  $out->{'text-align'} = 'center' if $switch_to_center;

  # only for nodes, not for edges
  if (!$self->isa('Graph::Easy::Edge'))
    {
    my $bc = $self->attribute('bordercolor');
    my $bw = $self->attribute('borderwidth');
    my $bs = $self->attribute('borderstyle');

    $out->{border} = Graph::Easy::_border_attribute_as_html( $bs, $bw, $bc );

    # we need to specify the border again for the inner div
    if ($shape !~ /(rounded|ellipse|circle)/)
      {
      my $DEF = $self->default_attribute('border');

      delete $out->{border} if $out->{border} =~ /^\s*\z/ || $out->{border} eq $DEF;
      }

    delete $out->{border} if $class eq 'node.anon' && $out->{border} && $out->{border} eq 'none';
    }

  # we compose the inner part as $inner_start . $label . $inner_end:
  my $inner_start = '';
  my $inner_end = '';

  if ($shape =~ /(rounded|ellipse|circle)/)
    {
    # set the fill on the inner part, but the background and no border on the <td>:
    my $inner_style = '';
    my $fill = $self->color_attribute('fill');
    $inner_style = 'background:' . $fill if $fill; 
    $inner_style .= ';border:' . $out->{border} if $out->{border};
    $inner_style =~ s/;\s?\z$//;				# remove '; ' at end

    delete $out->{background};
    delete $out->{border};

    my $td_style = '';
    $td_style = ' style="border: none;';
    my $bg = $self->color_attribute('background');
    $td_style .= "background: $bg\"";

    $html =~ s/##style##/$td_style/;

    $inner_end = '</span></div>';
    my $c = substr($shape, 0, 1); $c = 'c' if $c eq 'e';	# 'r' or 'c'

    my ($w,$h) = $self->dimensions();

    if ($shape eq 'circle')
      {
      # set both to the biggest size to enforce a circle shape
      my $r = $w;
      $r = $h if $h > $w;
      $w = $r; $h = $r;
      }

    $out->{top} = ($h / 2 + 0.5) . 'em'; delete $out->{top} if $out->{top} eq '1.5em';
    $h = ($h + 2) . 'em';
    $w = ($w + 2) . 'em';

    $inner_style .= ";width: $w; height: $h";

    $inner_style = " style='$inner_style'";
    $inner_start = "<div class='$c'$inner_style><span class='c'##style##>";
    }

  if ($class =~ /^group/)
    {
    delete $out->{border};
    delete $out->{background};
    my $group_class = $class; $group_class =~ s/\s.*//;		# "group gt" => "group"
    my @atr = qw/bordercolor borderwidth fill/;

    # transform "group_foo gr" to "group_foo" if border eq 'none' (for anon groups)
    my $border_style = $self->attribute('borderstyle');
    $c =~ s/\s+.*// if $border_style eq 'none';

    # only need the color for the label cell
    push @atr, 'color' if $self->{has_label};
    $name = '&nbsp;' unless $self->{has_label};
    for my $b (@atr)
      {
      my $def = $g->attribute($group_class,$b);
      my $v = $self->attribute($b);

      my $n = $b; $n = 'background' if $b eq 'fill';
      $out->{$n} = $v unless $v eq '' || $v eq $def;
      }
    $name = '&nbsp;' unless $name ne '';
    }

  # "shape: none;" or point means no border, and background instead fill color
  if ($shape =~ /^(point|none)\z/)
    {
    $out->{background} = $self->color_attribute('background'); 
    $out->{border} = 'none';
    }

  my $style = '';
  for my $atr (sort keys %$out)
    {
    if ($link ne '')
      {
      # put certain styles on the outer container, and not on the link
      next if $atr =~ /^(background|border)\z/;
      }
    $style .= "$atr: $out->{$atr}; ";
    }

  # bold, italic, underline etc. (but not for empty cells)
  $style .= $self->text_styles_as_css(1,1) if $name !~ /^(|&nbsp;)\z/;

  $style =~ s/;\s?\z$//;			# remove '; ' at end
  $style =~ s/\s+/ /g;				# '  ' => ' '
  $style =~ s/^\s+//;				# remove ' ' at front
  $style = " style=\"$style\"" if $style;

  my $end_tag = "</$tagb>\n";

  if ($link ne '')
    {
    # encode critical entities
    $link =~ s/\s/\+/g;				# space
    $link =~ s/'/%27/g;				# replace quotation marks

    my $outer_style = '';
    # put certain styles like border and background on the table cell:
    for my $s (qw/background border/)
      {
      $outer_style .= "$s: $out->{$s};" if exists $out->{$s};
      }
    $outer_style =~ s/;\s?\z$//;			# remove '; ' at end
    $outer_style = ' style="'.$outer_style.'"' if $outer_style;

    $inner_start =~ s/##style##/$outer_style/;	# remove from inner_start

    $html =~ s/##style##/$outer_style/;			# or HTML, depending
    $inner_start .= "<a href='$link'##style##>";	# and put on link
    $inner_end = '</a>'.$inner_end;
    }

  $c = " class='$c'" if $c ne '';
  $html .= ">$inner_start$name$inner_end$end_tag";
  $html =~ s/##class##/$c/;
  $html =~ s/##style##/$style/;

  $self->quoted_comment() . $html;
  }

sub angle
  {
  # return the rotation of the node, dependend on the rotate attribute
  # (and if relative, on the flow)
  my $self = shift;

  my $angle = $self->{att}->{rotate} || 0;

  $angle = 180 if $angle =~ /^(south|down)\z/;
  $angle = 0 if $angle =~ /^(north|up)\z/;
  $angle = 270 if $angle eq 'west';
  $angle = 90 if $angle eq 'east';

  # convert relative angles
  if ($angle =~ /^([+-]\d+|left|right|back|front|forward)\z/)
    {
    my $base_rot = $self->flow();
    $angle = 0 if $angle =~ /^(front|forward)\z/;
    $angle = 180 if $angle eq 'back';
    $angle = -90 if $angle eq 'left';
    $angle = 90 if $angle eq 'right';
    $angle = $base_rot + $angle + 0;	# 0 points up, so front points right
    $angle += 360 while $angle < 0;
    }

  $self->_croak("Illegal node angle $angle") if $angle !~ /^\d+\z/;

  $angle %= 360 if $angle > 359;

  $angle;
  }

# for determining the absolute parent flow
my $p_flow =
  {
  'east' => 90,
  'west' => 270,
  'north' => 0,
  'south' => 180,
  'up' => 0,
  'down' => 180,
  'back' => 270,
  'left' => 270,
  'right' => 90,
  'front' => 90,
  'forward' => 90,
  };

sub _parent_flow_absolute
  {
  # make parent flow absolute
  my ($self, $def)  = @_;

  return '90' if ref($self) eq 'Graph::Easy';

  my $flow = $self->parent()->raw_attribute('flow') || $def;

  return unless defined $flow;

  # in case of relative flow at parent, convert to absolute (right: east, left: west etc) 
  # so that "graph { flow: left; }" results in a westward flow
  my $f = $p_flow->{$flow}; $f = $flow unless defined $f;
  $f;
  }

sub flow
  {
  # Calculate the outgoing flow from the incoming flow and the flow at this
  # node (either from edge(s) or general flow). Returns an absolute flow:
  # See the online manual about flow for a reference and details.
  my $self = shift;

  no warnings 'recursion';

  my $cache = $self->{cache};
  return $cache->{flow} if exists $cache->{flow};

  # detected cycle, so break it
  return $cache->{flow} = $self->_parent_flow_absolute('90') if exists $self->{_flow};

  local $self->{_flow} = undef;		# endless loops really ruin our day

  my $in;
  my $flow = $self->{att}->{flow};

  $flow = $self->_parent_flow_absolute() if !defined $flow || $flow eq 'inherit';

  # if flow is absolute, return it early
  return $cache->{flow} = $flow if defined $flow && $flow =~ /^(0|90|180|270)\z/;
  return $cache->{flow} = Graph::Easy->_direction_as_number($flow)
    if defined $flow && $flow =~ /^(south|north|east|west|up|down)\z/;
  
  # for relative flows, compute the incoming flow as base flow

  # check all edges
  for my $e (values %{$self->{edges}})
    {
    # only count incoming edges
    next unless $e->{from} != $self && $e->{to} == $self;

    # if incoming edge has flow, we take this
    $in = $e->flow();
    # take the first match
    last if defined $in;
    }

  if (!defined $in)
    {
    # check all predecessors
    for my $e (values %{$self->{edges}})
      {
      my $pre = $e->{from};
      $pre = $e->{to} if $e->{bidirectional};
      if ($pre != $self)
        {
        $in = $pre->flow();
        # take the first match
        last if defined $in;
        }
      }
    }

  $in = $self->_parent_flow_absolute('90') unless defined $in;

  $flow = Graph::Easy->_direction_as_number($in) unless defined $flow;

  $cache->{flow} = Graph::Easy->_flow_as_direction($in,$flow);
  }

#############################################################################
# multi-celled nodes

sub _calc_size
  {
  # Calculate the base size in cells from the attributes (before grow())
  # Will return a hash that denotes in which direction the node should grow.
  my $self = shift;

  # If specified only one of "rows" or "columns", then grow the node
  # only in the unspecified direction. Default is grow both.
  my $grow_sides = { cx => 1, cy => 1 };

  my $r = $self->{att}->{rows};
  my $c = $self->{att}->{columns};
  delete $grow_sides->{cy} if defined $r && !defined $c;
  delete $grow_sides->{cx} if defined $c && !defined $r;

  $r = $self->attribute('rows') unless defined $r;
  $c = $self->attribute('columns') unless defined $c;

  $self->{cy} = abs($r || 1);
  $self->{cx} = abs($c || 1);

  $grow_sides;
  }

sub _grow
  {
  # Grows the node until it has sufficient cells for all incoming/outgoing
  # edges. The initial size will be based upon the attributes 'size' (or
  # 'rows' or 'columns', depending on which is set)
  my $self = shift;

  # XXX TODO: grow the node based on its label dimensions
#  my ($w,$h) = $self->dimensions();
#
#  my $cx = int(($w+2) / 5) || 1;
#  my $cy = int(($h) / 3) || 1;
#
#  $self->{cx} = $cx if $cx > $self->{cx};
#  $self->{cy} = $cy if $cy > $self->{cy};

  # satisfy the edge start/end port constraints:

  # We calculate a bitmap (vector) for each side, and mark each
  # used port. Edges that have an unspecified port will just be
  # counted.

  # bitmap for each side:
  my $vec = { north => '', south => '', east => '', west => '' };
  # number of edges constrained to one side, but without port number
  my $cnt = { north => 0, south => 0, east => 0, west => 0 };
  # number of edges constrained to one side, with port number
  my $portnr = { north => 0, south => 0, east => 0, west => 0 };
  # max number of ports for each side
  my $max = { north => 0, south => 0, east => 0, west => 0 };

  my @idx = ( [ 'start', 'from' ], [ 'end', 'to' ] );
  # number of slots we need to edges without port restrictions
  my $unspecified = 0;

  # count of outgoing edges
  my $outgoing = 0;

  for my $e (values %{$self->{edges}})
    {
    # count outgoing edges
    $outgoing++ if $e->{from} == $self;

    # do always both ends, because self-loops can start AND end at this node:
    for my $end (0..1)
      {
      # if the edge starts/ends here
      if ($e->{$idx[$end]->[1]} == $self)		# from/to
	{
	my ($side, $nr) = $e->port($idx[$end]->[0]);	# start/end

	if (defined $side)
	  {
	  if (!defined $nr || $nr eq '')
	    {
	    # no port number specified, so just count
	    $cnt->{$side}++;
	    }
	  else
	    {
	    # mark the bit in the vector
	    # limit to four digits
	    $nr = 9999 if abs($nr) > 9999; 

	    # if slot was not used yet, count it
	    $portnr->{$side} ++ if vec($vec->{$side}, $nr, 1) == 0x0;

	    # calculate max number of ports
            $nr = abs($nr) - 1 if $nr < 0;		# 3 => 3, -3 => 2
            $nr++;					# 3 => 4, -3 => 3

	    # mark as used
	    vec($vec->{$side}, $nr - 1, 1) = 0x01;

	    $max->{$side} = $nr if $nr > $max->{$side};
	    }
          }
        else
          {
          $unspecified ++;
          }
        } # end if port is constrained
      } # end for start/end port
    } # end for all edges

  for my $e (values %{$self->{edges}})
    {
    # the loop above will count all self-loops twice when they are
    # unrestricted. So subtract these again. Restricted self-loops
    # might start at one port and end at another, and this case is
    # covered correctly by the code above.
    $unspecified -- if $e->{to} == $e->{from};
    }

  # Shortcut, if the number of edges is < 4 and we have not restrictions,
  # then a 1x1 node suffices
  if ($unspecified < 4 && ($unspecified == keys %{$self->{edges}}))
    {
    $self->_calc_size();
    return $self;
    }
 
  my $need = {};
  my $free = {};
  for my $side (qw/north south east west/)
    {
    # maximum number of ports we need to reserve, minus edges constrained
    # to unique ports: free ports on that side
    $free->{$side} = $max->{$side} - $portnr->{$side};
    $need->{$side} = $max->{$side};
    if ($free->{$side} < 2 * $cnt->{$side})
      {
      $need->{$side} += 2 * $cnt->{$side} - $free->{$side} - 1;
      }
    }
  # now $need contains for each side the absolute min. number of ports we need

#  use Data::Dumper; 
#  print STDERR "# port contraints for $self->{name}:\n";
#  print STDERR "# count: ", Dumper($cnt), "# max: ", Dumper($max),"\n";
#  print STDERR "# ports: ", Dumper($portnr),"\n";
#  print STDERR "# need : ", Dumper($need),"\n";
#  print STDERR "# free : ", Dumper($free),"\n";
 
  # calculate min. size in X and Y direction
  my $min_x = $need->{north}; $min_x = $need->{south} if $need->{south} > $min_x;
  my $min_y = $need->{west}; $min_y = $need->{east} if $need->{east} > $min_y;

  my $grow_sides = $self->_calc_size();

  # increase the size if the minimum required size is not met
  $self->{cx} = $min_x if $min_x > $self->{cx};
  $self->{cy} = $min_y if $min_y > $self->{cy};

  my $flow = $self->flow();

  # if this is a sink node, grow it more by ignoring free ports on the front side
  my $front_side = 'east';
  $front_side = 'west' if $flow == 270;
  $front_side = 'south' if $flow == 180;
  $front_side = 'north' if $flow == 0;

  # now grow the node based on the general flow first VER, then HOR
  my $grow = 0;					# index into @grow_what
  my @grow_what = sort keys %$grow_sides;	# 'cx', 'cy' or 'cx' or 'cy'

  if (keys %$grow_sides > 1)
    {
    # for left/right flow, swap the growing around
    @grow_what = ( 'cy', 'cx' ) if $flow == 90 || $flow == 270;
    }

  # fake a non-sink node for nodes with an offset/children
  $outgoing = 1 if ref($self->{origin}) || keys %{$self->{children}} > 0;

  while ( 3 < 5 )
    {
    # calculate whether we already found a space for all edges
    my $free_ports = 0;
    for my $side (qw/north south/)
      {
      # if this is a sink node, grow it more by ignoring free ports on the front side
      next if $outgoing == 0 && $front_side eq $side;
      $free_ports += 1 + int(($self->{cx} - $cnt->{$side} - $portnr->{$side}) / 2);
      }     
    for my $side (qw/east west/)
      {
      # if this is a sink node, grow it more by ignoring free ports on the front side
      next if $outgoing == 0 && $front_side eq $side;
      $free_ports += 1 + int(($self->{cy} - $cnt->{$side} - $portnr->{$side}) / 2);
      }
    last if $free_ports >= $unspecified;

    $self->{ $grow_what[$grow] } += 2;

    $grow ++; $grow = 0 if $grow >= @grow_what;
    }

  $self;
  }

sub is_multicelled
  {
  # return true if node consist of more than one cell
  my $self = shift;

  $self->_calc_size() unless defined $self->{cx};

  $self->{cx} + $self->{cy} <=> 2;	# 1 + 1 == 2: no, cx + xy != 2: yes
  }

sub is_anon
  {
  # normal nodes are not anon nodes (but "::Anon" are)
  0;
  }

#############################################################################
# accessor methods

sub _un_escape
  {
  # replace \N, \G, \T, \H and \E (depending on type)
  # if $label is false, also replace \L with the label
  my ($self, $txt, $do_label) = @_;
 
  # for edges:
  if (exists $self->{edge})
    {
    my $e = $self->{edge};
    $txt =~ s/\\E/$e->{from}->{name}\->$e->{to}->{name}/g;
    $txt =~ s/\\T/$e->{from}->{name}/g;
    $txt =~ s/\\H/$e->{to}->{name}/g;
    # \N for edges is the label of the edge
    if ($txt =~ /\\N/)
      {
      my $l = $self->label();
      $txt =~ s/\\N/$l/g;
      }
    }
  else
    {
    # \N for nodes
    $txt =~ s/\\N/$self->{name}/g;
    }
  # \L with the label
  if ($txt =~ /\\L/ && $do_label)
    {
    my $l = $self->label();
    $txt =~ s/\\L/$l/g;
    }

  # \G for edges and nodes
  if ($txt =~ /\\G/)
    {
    my $g = '';
    # the graph itself
    $g = $self->attribute('title') unless ref($self->{graph});
    # any nodes/edges/groups in it
    $g = $self->{graph}->label() if ref($self->{graph});
    $txt =~ s/\\G/$g/g;
    }
  $txt;
  }

sub title
  {
  # Returns a title of the node (or '', if none was set), which can be
  # used for mouse-over titles

  my $self = shift;

  my $title = $self->attribute('title');
  if ($title eq '')
    {
    my $autotitle = $self->attribute('autotitle');
    if (defined $autotitle)
      {
      $title = '';					# default is none

      if ($autotitle eq 'name')				# use name
	{
        $title = $self->{name};
	# edges do not have a name and fall back on their label
        $title = $self->{att}->{label} unless defined $title;
	}

      if ($autotitle eq 'label')
        {
        $title = $self->{name};				# fallback to name
        # defined to avoid overriding "name" with the non-existant label attribute
	# do not use label() here, but the "raw" label of the edge:
        my $label = $self->label(); $title = $label if defined $label;
        }

      $title = $self->link() if $autotitle eq 'link';
      }
    $title = '' unless defined $title;
    }

  $title = $self->_un_escape($title, 1) if !$_[0] && $title =~ /\\[EGHNTL]/;

  $title;
  }

sub background
  {
  # get the background for this group/edge cell, honouring group membership.
  my $self = shift;

  $self->color_attribute('background');
  }

sub label
  {
  my $self = shift;

  # shortcut to speed it up a bit:
  my $label = $self->{att}->{label};
  $label = $self->attribute('label') unless defined $label;

  # for autosplit nodes, use their auto-label first (unless already got 
  # a label from the class):
  $label = $self->{autosplit_label} unless defined $label;
  $label = $self->{name} unless defined $label;

  return '' unless defined $label;

  if ($label ne '')
    {
    my $len = $self->attribute('autolabel');
    if ($len ne '')
      {
      # allow the old format (pre v0.49), too: "name,12" => 12
      $len =~ s/^name\s*,\s*//;			
      # restrict to sane values
      $len = abs($len || 0); $len = 99999 if $len > 99999;
      if (length($label) > $len)
        {
        my $g = $self->{graph} || {};
	if ((($g->{_ascii_style}) || 0) == 0)
	  {
	  # ASCII output
	  $len = int($len / 2) - 3; $len = 0 if $len < 0;
	  $label = substr($label, 0, $len) . ' ... ' . substr($label, -$len, $len);
	  }
	else
	  {
	  $len = int($len / 2) - 2; $len = 0 if $len < 0;
	  $label = substr($label, 0, $len) . ' … ' . substr($label, -$len, $len);
	  }
        }
      }
    }

  $label = $self->_un_escape($label) if !$_[0] && $label =~ /\\[EGHNT]/;

  $label;
  }

sub name
  {
  my $self = shift;

  $self->{name};
  }

sub x
  {
  my $self = shift;

  $self->{x};
  }

sub y
  {
  my $self = shift;

  $self->{y};
  }

sub width
  {
  my $self = shift;

  $self->{w};
  }

sub height
  {
  my $self = shift;

  $self->{h};
  }

sub origin
  {
  # Returns node that this node is relative to or undef, if not.
  my $self = shift;

  $self->{origin};
  }

sub pos
  {
  my $self = shift;

  ($self->{x} || 0, $self->{y} || 0);
  }

sub offset
  {
  my $self = shift;

  ($self->{dx} || 0, $self->{dy} || 0);
  }

sub columns
  {
  my $self = shift;

  $self->_calc_size() unless defined $self->{cx};

  $self->{cx};
  }

sub rows
  {
  my $self = shift;

  $self->_calc_size() unless defined $self->{cy};

  $self->{cy};
  }

sub size
  {
  my $self = shift;

  $self->_calc_size() unless defined $self->{cx};

  ($self->{cx}, $self->{cy});
  }

sub shape
  {
  my $self = shift;

  my $shape;
  $shape = $self->{att}->{shape} if exists $self->{att}->{shape};
  $shape = $self->attribute('shape') unless defined $shape;
  $shape;
  }

sub dimensions
  {
  # Returns the minimum dimensions of the node/cell derived from the
  # label or name, in characters.
  my $self = shift;

  my $align = $self->attribute('align');
  my ($lines,$aligns) = $self->_aligned_label($align);

  my $w = 0; my $h = scalar @$lines;
  foreach my $line (@$lines)
    {
    $w = length($line) if length($line) > $w;
    }
  ($w,$h);
  }

#############################################################################
# edges and connections

sub edges_to
  {
  # Return all the edge objects that start at this vertex and go to $other.
  my ($self, $other) = @_;

  # no graph, no dice
  return unless ref $self->{graph};

  my @edges;
  for my $edge (values %{$self->{edges}})
    {
    push @edges, $edge if $edge->{from} == $self && $edge->{to} == $other;
    }
  @edges;
  }

sub edges_at_port
  {
  # return all edges that share the same given port
  my ($self, $attr, $side, $port) = @_;

  # Must be "start" or "end"
  return () unless $attr =~ /^(start|end)\z/;

  $self->_croak('side not defined') unless defined $side;
  $self->_croak('port not defined') unless defined $port;

  my @edges;
  for my $e (values %{$self->{edges}})
    {
    # skip edges ending here if we look at start
    next if $e->{to} eq $self && $attr eq 'start';
    # skip edges starting here if we look at end
    next if $e->{from} eq $self && $attr eq 'end';

    my ($s_p,@ss_p) = $e->port($attr);	
    next unless defined $s_p;

    # same side and same port number?
    push @edges, $e 
      if $s_p eq $side && @ss_p == 1 && $ss_p[0] eq $port;
    }

  @edges;
  }

sub shared_edges
  {
  # return all edges that share one port with another edge
  my ($self) = @_;

  my @edges;
  for my $e (values %{$self->{edges}})
    {
    my ($s_p,@ss_p) = $e->port('start');
    push @edges, $e if defined $s_p;
    my ($e_p,@ee_p) = $e->port('end');
    push @edges, $e if defined $e_p;
    }
  @edges;
  }

sub nodes_sharing_start
  {
  # return all nodes that share an edge start with an
  # edge from that node
  my ($self, $side, @port) = @_;

  my @edges = $self->edges_at_port('start',$side,@port);

  my $nodes;
  for my $e (@edges)
    {
    # ignore self-loops
    my $to = $e->{to};
    next if $to == $self;

    # remove duplicates
    $nodes->{ $to->{name} } = $to;
    }

  (values %$nodes);
  }

sub nodes_sharing_end
  {
  # return all nodes that share an edge end with an
  # edge from that node
  my ($self, $side, @port) = @_;

  my @edges = $self->edges_at_port('end',$side,@port);

  my $nodes;
  for my $e (@edges)
    {
    # ignore self-loops
    my $from = $e->{from};
    next if $from == $self;

    # remove duplicates
    $nodes->{ $from->{name} } = $from;
    }

  (values %$nodes);
  }

sub incoming
  {
  # return all edges that end at this node
  my $self = shift;

  # no graph, no dice
  return unless ref $self->{graph};

  if (!wantarray)
    {
    my $count = 0;
    for my $edge (values %{$self->{edges}})
      {
      $count++ if $edge->{to} == $self;
      }
    return $count;
    }

  my @edges;
  for my $edge (values %{$self->{edges}})
    {
    push @edges, $edge if $edge->{to} == $self;
    }
  @edges;
  }

sub outgoing
  {
  # return all edges that start at this node
  my $self = shift;

  # no graph, no dice
  return unless ref $self->{graph};

  if (!wantarray)
    {
    my $count = 0;
    for my $edge (values %{$self->{edges}})
      {
      $count++ if $edge->{from} == $self;
      }
    return $count;
    }

  my @edges;
  for my $edge (values %{$self->{edges}})
    {
    push @edges, $edge if $edge->{from} == $self;
    }
  @edges;
  }

sub connections
  {
  # return number of connections (incoming+outgoing)
  my $self = shift;

  return 0 unless defined $self->{graph};

  # We need to count the connections, because "[A]->[A]" creates
  # two connections on "A", but only one edge! 
  my $con = 0;
  for my $edge (values %{$self->{edges}})
    {
    $con ++ if $edge->{to} == $self;
    $con ++ if $edge->{from} == $self;
    }
  $con;
  }

sub edges
  {
  # return all the edges
  my $self = shift;

  # no graph, no dice
  return unless ref $self->{graph};

  wantarray ? values %{$self->{edges}} : scalar keys %{$self->{edges}};
  }

sub sorted_successors
  {
  # return successors of the node sorted by their chain value
  # (e.g. successors with more successors first) 
  my $self = shift;

  my @suc = sort {
       scalar $b->successors() <=> scalar $a->successors() ||
       scalar $a->{name} cmp scalar $b->{name}
       } $self->successors();
  @suc;
  }

sub successors
  {
  # return all nodes (as objects) we are linked to
  my $self = shift;

  return () unless defined $self->{graph};

  my %suc;
  for my $edge (values %{$self->{edges}})
    {
    next unless $edge->{from} == $self;
    $suc{$edge->{to}->{id}} = $edge->{to};	# weed out doubles
    }
  values %suc;
  }

sub predecessors
  {
  # return all nodes (as objects) that link to us
  my $self = shift;

  return () unless defined $self->{graph};

  my %pre;
  for my $edge (values %{$self->{edges}})
    {
    next unless $edge->{to} == $self;
    $pre{$edge->{from}->{id}} = $edge->{from};	# weed out doubles
    }
  values %pre;
  }

sub has_predecessors
  {
  # return true if node has incoming edges (even from itself)
  my $self = shift;

  return undef unless defined $self->{graph};

  for my $edge (values %{$self->{edges}})
    {
    return 1 if $edge->{to} == $self;		# found one
    }
  0;						# found none
  }

sub has_as_predecessor
  {
  # return true if other is a predecessor of node
  my ($self,$other) = @_;

  return () unless defined $self->{graph};

  for my $edge (values %{$self->{edges}})
    {
    return 1 if 
	$edge->{to} == $self && $edge->{from} == $other;	# found one
    }
  0;						# found none
  }

sub has_as_successor
  {
  # return true if other is a successor of node
  my ($self,$other) = @_;

  return () unless defined $self->{graph};

  for my $edge (values %{$self->{edges}})
    {
    return 1 if
	$edge->{from} == $self && $edge->{to} == $other;	# found one

    }
  0;						# found none
  }

#############################################################################
# relatively placed nodes

sub relative_to
  {
  # Sets the new origin if passed a Graph::Easy::Node object.
  my ($self,$parent,$dx,$dy) = @_;

  if (!ref($parent) || !$parent->isa('Graph::Easy::Node'))
    {
    require Carp;
    Carp::confess("Can't set origin to non-node object $parent");
    }

  my $grandpa = $parent->find_grandparent();
  if ($grandpa == $self)
    {
    require Carp;
    Carp::confess( "Detected loop in origin-chain:"
                  ." tried to set origin of '$self->{name}' to my own grandchild $parent->{name}");
    }

  # unregister us with our old parent
  delete $self->{origin}->{children}->{$self->{id}} if defined $self->{origin};

  $self->{origin} = $parent;
  $self->{dx} = $dx if defined $dx;
  $self->{dy} = $dy if defined $dy;
  $self->{dx} = 0 unless defined $self->{dx};
  $self->{dy} = 0 unless defined $self->{dy};

  # register us as a new child
  $parent->{children}->{$self->{id}} = $self;

  $self;
  }

sub find_grandparent
  {
  # For a node that has no origin (is not relative to another), returns
  # $self. For all others, follows the chain of origin back until we
  # hit a node without a parent. This code assumes there are no loops,
  # which origin() prevents from happening.
  my $cur = shift;

  if (wantarray)
    {
    my $ox = 0;
    my $oy = 0;
    while (defined($cur->{origin}))
      {
      $ox -= $cur->{dx};
      $oy -= $cur->{dy};
      $cur = $cur->{origin};
      }
    return ($cur,$ox,$oy);
    }

  while (defined($cur->{origin}))
    {
    $cur = $cur->{origin};
    }
  
  $cur;
  }

#############################################################################
# attributes

sub del_attribute
  {
  my ($self, $name) = @_;

  # font-size => fontsize
  $name = $att_aliases->{$name} if exists $att_aliases->{$name};

  $self->{cache} = {};

  my $a = $self->{att};
  delete $a->{$name};
  if ($name eq 'size')
    {
    delete $a->{rows};
    delete $a->{columns};
    }
  if ($name eq 'border')
    {
    delete $a->{borderstyle};
    delete $a->{borderwidth};
    delete $a->{bordercolor};
    }
  $self;
  }

sub set_attribute
  {
  my ($self, $name, $v, $class) = @_;

  $self->{cache} = {};

  $name = 'undef' unless defined $name;
  $v = 'undef' unless defined $v;

  # font-size => fontsize
  $name = $att_aliases->{$name} if exists $att_aliases->{$name};

  # edge.cities => edge
  $class = $self->main_class() unless defined $class;

  # remove quotation marks, but not for titles, labels etc
  my $val = Graph::Easy->unquote_attribute($class,$name,$v);

  my $g = $self->{graph};
  
  $g->{score} = undef if $g;	# invalidate layout to force a new layout

  my $strict = 0; $strict = $g->{strict} if $g;
  if ($strict)
    {
    my ($rc, $newname, $v) = $g->validate_attribute($name,$val,$class);

    return if defined $rc;		# error?

    $val = $v;
    }

  if ($name eq 'class')
    {
    $self->sub_class($val);
    return $val;
    }
  elsif ($name eq 'group')
    {
    $self->add_to_group($val);
    return $val;
    }
  elsif ($name eq 'border')
    {
    my $c = $self->{att};

    ($c->{borderstyle}, $c->{borderwidth}, $c->{bordercolor}) =
	$g->split_border_attributes( $val );

    return $val;
    }

  if ($name =~ /^(columns|rows|size)\z/)
    {
    if ($name eq 'size')
      {
      $val =~ /^(\d+)\s*,\s*(\d+)\z/;
      my ($cx, $cy) = (abs(int($1)),abs(int($2)));
      ($self->{att}->{columns}, $self->{att}->{rows}) = ($cx, $cy);
      }
    else
      {
      $self->{att}->{$name} = abs(int($val));
      }
    return $self;
    }

  if ($name =~ /^(origin|offset)\z/)
    {
    # Only the first autosplit node get the offset/origin
    return $self if exists $self->{autosplit} && !defined $self->{autosplit};

    if ($name eq 'origin')
      {
      # if it doesn't exist, add it
      my $org = $self->{graph}->add_node($val);
      $self->relative_to($org);
  
      # set the attributes, too, so get_attribute('origin') works, too:
      $self->{att}->{origin} = $org->{name};
      }
    else
      {
      # offset
      # if it doesn't exist, add it
      my ($x,$y) = split/\s*,\s*/, $val;
      $x = int($x);
      $y = int($y);
      if ($x == 0 && $y == 0)
        {
        $g->error("Error in attribute: 'offset' is 0,0 in node $self->{name} with class '$class'");
        return;
        }
      $self->{dx} = $x;
      $self->{dy} = $y;

      # set the attributes, too, so get_attribute('origin') works, too:
      $self->{att}->{offset} = "$self->{dx},$self->{dy}";
      }
    return $self;
    }

  $self->{att}->{$name} = $val;
  }

sub set_attributes
  {
  my ($self, $atr, $index) = @_;

  foreach my $n (keys %$atr)
    {
    my $val = $atr->{$n};
    $val = $val->[$index] if ref($val) eq 'ARRAY' && defined $index;

    next if !defined $val || $val eq '';

    $n eq 'class' ? $self->sub_class($val) : $self->set_attribute($n, $val);
    }
  $self;
  }

BEGIN
  {
  # some handy aliases
  *text_styles_as_css = \&Graph::Easy::text_styles_as_css;
  *text_styles = \&Graph::Easy::text_styles;
  *_font_size_in_pixels = \&Graph::Easy::_font_size_in_pixels;
  *get_color_attribute = \&color_attribute;
  *link = \&Graph::Easy::link;
  *border_attribute = \&Graph::Easy::border_attribute;
  *get_attributes = \&Graph::Easy::get_attributes;
  *get_attribute = \&Graph::Easy::attribute;
  *raw_attribute = \&Graph::Easy::raw_attribute;
  *get_raw_attribute = \&Graph::Easy::raw_attribute;
  *raw_color_attribute = \&Graph::Easy::raw_color_attribute;
  *raw_attributes = \&Graph::Easy::raw_attributes;
  *raw_attributes = \&Graph::Easy::raw_attributes;
  *attribute = \&Graph::Easy::attribute;
  *color_attribute = \&Graph::Easy::color_attribute;
  *default_attribute = \&Graph::Easy::default_attribute;
  $att_aliases = Graph::Easy::_att_aliases();
  }

#############################################################################

sub group
  {
  # return the group this object belongs to
  my $self = shift;

  $self->{group};
  }

sub add_to_group
  {
  my ($self,$group) = @_;
 
  my $graph = $self->{graph};				# shortcut

  # delete from old group if nec.
  $self->{group}->del_member($self) if ref $self->{group};

  # if passed a group name, create or find group object
  $group = $graph->add_group($group) if (!ref($group) && $graph);

  # To make attribute('group') work:
  $self->{att}->{group} = $group->{name};

  $group->add_member($self);

  $self;
  }

sub parent
  {
  # return parent object, either the group the node belongs to, or the graph
  my $self = shift;

  my $p = $self->{graph};

  $p = $self->{group} if ref($self->{group});

  $p;
  }

sub _update_boundaries
  {
  my ($self, $parent) = @_;

  # XXX TODO: use current layout parent for recursive layouter:
  $parent = $self->{graph};

  # cache max boundaries for A* algorithmn:

  my $x = $self->{x};
  my $y = $self->{y};

  # create the cache if it doesn't already exist
  $parent->{cache} = {} unless ref($parent->{cache});

  my $cache = $parent->{cache};
  
  $cache->{min_x} = $x if !defined $cache->{min_x} || $x < $cache->{min_x};
  $cache->{min_y} = $y if !defined $cache->{min_y} || $y < $cache->{min_y};

  $x = $x + ($self->{cx}||1) - 1;
  $y = $y + ($self->{cy}||1) - 1;
  $cache->{max_x} = $x if !defined $cache->{max_x} || $x > $cache->{max_x};
  $cache->{max_y} = $y if !defined $cache->{max_y} || $y > $cache->{max_y};

  if (($parent->{debug}||0) > 1)
    {
    my $n = $self->{name}; $n = $self unless defined $n;
    print STDERR "Update boundaries for $n (parent $parent) at $x, $y\n";
  
    print STDERR "Boundaries are now: " .
		 "$cache->{min_x},$cache->{min_y} => $cache->{max_x},$cache->{max_y}\n";
    }

  $self;
  }

1;
__END__

=head1 NAME

Graph::Easy::Node - Represents a node in a Graph::Easy graph

=head1 SYNOPSIS

        use Graph::Easy::Node;

	my $bonn = Graph::Easy::Node->new('Bonn');

	$bonn->set_attribute('border', 'solid 1px black');

	my $berlin = Graph::Easy::Node->new( name => 'Berlin' );

=head1 DESCRIPTION

A C<Graph::Easy::Node> represents a node in a simple graph. Each
node has contents (a text, an image or another graph), and dimension plus
an origin. The origin is typically determined by a graph layouter module
like L<Graph::Easy>.

=head1 METHODS

Apart from the methods of the base class L<Graph::Easy::Base>, a
C<Graph::Easy::Node> has the following methods:

=head2 new()

        my $node = Graph::Easy::Node->new( name => 'node name' );
        my $node = Graph::Easy::Node->new( 'node name' );

Creates a new node. If you want to add the node to a Graph::Easy object,
then please use the following to create the node object:

	my $node = $graph->add_node('Node name');

You can then use C<< $node->set_attribute(); >>
or C<< $node->set_attributes(); >> to set the new Node's attributes.

=head2 as_ascii()

	my $ascii = $node->as_ascii();

Return the node as a little box drawn in ASCII art as a string.

=head2 as_txt()

	my $txt = $node->as_txt();

Return the node in simple txt format, including attributes.

=head2 as_svg()

	my $svg = $node->as_svg();

Returns the node as Scalable Vector Graphic. The actual code for
that routine is defined L<Graph::Easy::As_svg.pm>.

=head2 as_graphviz()

B<For internal use> mostly - use at your own risk.

	my $txt = $node->as_graphviz();

Returns the node as graphviz compatible text which can be fed
to dot etc to create images.

One needs to load L<Graph::Easy::As_graphviz> first before this method
can be called.


=head2 as_graphviz_txt()

B<For internal use> mostly - use at your own risk.

	my $txt = $node->as_graphviz_txt();

Return only the node itself (without attributes) as a graphviz representation.

One needs to load L<Graph::Easy::As_graphviz> first before this method
can be called.


=head2 as_pure_txt()

	my $txt = $node->as_pure_txt();

Return the node in simple txt format, without the attributes.

=head2 text_styles_as_css()

	my $styles = $graph->text_styles_as_css();	# or $edge->...() etc.

Return the text styles as a chunk of CSS styling that can be embedded into
a C< style="" > parameter.

=head2 as_html()

	my $html = $node->as_html();

Return the node as HTML code.

=head2 attribute(), get_attribute()

	$node->attribute('border-style');

Returns the respective attribute of the node or undef if it
was not set. If there is a default attribute for all nodes
of the specific class the node is in, then this will be returned.

=head2 get_attributes()

        my $att = $object->get_attributes();

Return all effective attributes on this object (graph/node/group/edge) as
an anonymous hash ref. This respects inheritance and default values.

Note that this does not include custom attributes.

See also L<get_custom_attributes> and L<raw_attributes()>.

=head2 get_custom_attributes()

	my $att = $object->get_custom_attributes();

Return all the custom attributes on this object (graph/node/group/edge) as
an anonymous hash ref.

=head2 custom_attributes()

    my $att = $object->custom_attributes();

C<< custom_attributes() >> is an alias for L<< get_custom_attributes >>.

=head2 raw_attributes()

        my $att = $object->get_attributes();

Return all set attributes on this object (graph/node/group/edge) as
an anonymous hash ref. This respects inheritance, but does not include
default values for unset attributes.

See also L<get_attributes()>.

=head2 default_attribute()

	my $def = $graph->default_attribute($class, 'fill');

Returns the default value for the given attribute B<in the class>
of the object.

The default attribute is the value that will be used if
the attribute on the object itself, as well as the attribute
on the class is unset.

To find out what attribute is on the class, use the three-arg form
of L<attribute> on the graph:

	my $g = Graph::Easy->new();
	my $node = $g->add_node('Berlin');

	print $node->attribute('fill'), "\n";		# print "white"
	print $node->default_attribute('fill'), "\n";	# print "white"
	print $g->attribute('node','fill'), "\n";	# print "white"

	$g->set_attribute('node','fill','red');		# class is "red"
	$node->set_attribute('fill','green');		# this object is "green"

	print $node->attribute('fill'), "\n";		# print "green"
	print $node->default_attribute('fill'), "\n";	# print "white"
	print $g->attribute('node','fill'), "\n";	# print "red"

See also L<raw_attribute()>.

=head2 attributes_as_txt

	my $txt = $node->attributes_as_txt();

Return the attributes of this node as text description. This is used
by the C<< $graph->as_txt() >> code and there should be no reason
to use this function on your own.

=head2 set_attribute()

	$node->set_attribute('border-style', 'none');

Sets the specified attribute of this (and only this!) node to the
specified value.

=head2 del_attribute()

	$node->del_attribute('border-style');

Deletes the specified attribute of this (and only this!) node.

=head2 set_attributes()

	$node->set_attributes( $hash );

Sets all attributes specified in C<$hash> as key => value pairs in this
(and only this!) node.

=head2 border_attribute()

	my $border = $node->border_attribute();

Assembles the C<border-width>, C<border-color> and C<border-style> attributes
into a string like "solid 1px red".

=head2 color_attribute()

	# returns f.i. #ff0000
	my $color = $node->get_color_attribute( 'fill' );

Just like get_attribute(), but only for colors, and returns them as hex,
using the current colorscheme.

=head2 get_color_attribute()

Is an alias for L<color_attribute()>.

=head2 raw_attribute(), get_raw_attribute()

	my $value = $object->raw_attribute( $name );

Return the value of attribute C<$name> from the object it this
method is called on (graph, node, edge, group etc.). If the
attribute is not set on the object itself, returns undef.

This method respects inheritance, so an attribute value of 'inherit'
on an object will make the method return the inherited value:

	my $g = Graph::Easy->new();
	my $n = $g->add_node('A');

	$g->set_attribute('color','red');

	print $n->raw_attribute('color');		# undef
	$n->set_attribute('color','inherit');
	print $n->raw_attribute('color');		# 'red'

See also L<attribute()>.

=head2 raw_color_attribute()

	# returns f.i. #ff0000
	my $color = $graph->raw_color_attribute('color' );

Just like L<raw_attribute()>, but only for colors, and returns them as hex,
using the current colorscheme.

If the attribute is not set on the object, returns C<undef>.

=head2 text_styles()

        my $styles = $node->text_styles();
        if ($styles->{'italic'})
          {
          print 'is italic\n';
          }

Return a hash with the given text-style properties, aka 'underline', 'bold' etc.

=head2 find_grandparent()

	my $grandpa = $node->find_grandparent(); 

For a node that has no origin (is not relative to another), returns
C<$node>. For all others, follows the chain of origin back until
a node without a parent is found and returns this node.
This code assumes there are no loops, which C<origin()> prevents from
happening.

=head2 name()

	my $name = $node->name();

Return the name of the node. In a graph, each node has a unique name,
which, unless a node label is set, will be displayed when rendering the
graph.

=head2 label()

	my $label = $node->label();
	my $label = $node->label(1);		# raw

Return the label of the node. If no label was set, returns the C<name>
of the node.

If the optional parameter is true, then the label will returned 'raw',
that is any potential escape of the form C<\N>, C<\E>, C<\G>, C<\T>
or C<\H> will not be left alone and not be replaced.

=head2 background()

	my $bg = $node->background();

Returns the background color. This method honours group membership and
inheritance.

=head2 quoted_comment()

	my $cmt = $node->comment();

Comment of this object, quoted suitable as to be embedded into HTML/SVG.
Returns the empty string if this object doesn't have a comment set.

=head2 title()

	my $title = $node->title();
	my $title = $node->title(1);		# raw

Returns a potential title that can be used for mouse-over effects.
If no title was set (or autogenerated), will return an empty string.

If the optional parameter is true, then the title will returned 'raw',
that is any potential escape of the form C<\N>, C<\E>, C<\G>, C<\T>
or C<\H> will be left alone and not be replaced.

=head2 link()

	my $link = $node->link();
	my $link = $node->link(1);		# raw

Returns the URL, build from the C<linkbase> and C<link> (or C<autolink>)
attributes.  If the node has no link associated with it, return an empty
string.

If the optional parameter is true, then the link will returned 'raw',
that is any potential escape of the form C<\N>, C<\E>, C<\G>, C<\T>
or C<\H> will not be left alone and not be replaced.

=head2 dimensions()

	my ($w,$h) = $node->dimensions();

Returns the dimensions of the node/cell derived from the label (or name) in characters.
Assumes the label/name has literal '\n' replaced by "\n".

=head2 size()

	my ($cx,$cy) = $node->size();

Returns the node size in cells.

=head2 contents()

	my $contents = $node->contents();

For nested nodes, returns the contents of the node.

=head2 width()

	my $width = $node->width();

Returns the width of the node. This is a unitless number.

=head2 height()

	my $height = $node->height();

Returns the height of the node. This is a unitless number.

=head2 columns()

	my $cols = $node->columns();

Returns the number of columns (in cells) that this node occupies.

=head2 rows()

	my $cols = $node->rows();

Returns the number of rows (in cells) that this node occupies.

=head2 is_multicelled()

	if ($node->is_multicelled())
	  {
	  ...
	  }

Returns true if the node consists of more than one cell. See als
L<rows()> and L<cols()>.

=head2 is_anon()

	if ($node->is_anon())
	  {
	  ...
	  }

Returns true if the node is an anonymous node. False for C<Graph::Easy::Node>
objects, and true for C<Graph::Easy::Node::Anon>.

=head2 pos()

	my ($x,$y) = $node->pos();

Returns the position of the node. Initially, this is undef, and will be
set from L<Graph::Easy::layout()>. Only valid during the layout phase.

=head2 offset()

	my ($dx,$dy) = $node->offset();

Returns the position of the node relativ to the origin. Returns C<(0,0)> if
the origin node was not sset.

=head2 x()

	my $x = $node->x();

Returns the X position of the node. Initially, this is undef, and will be
set from L<Graph::Easy::layout()>. Only valid during the layout phase.

=head2 y()

	my $y = $node->y();

Returns the Y position of the node. Initially, this is undef, and will be
set from L<Graph::Easy::layout()>. Only valid during the layout phase.

=head2 id()

	my $id = $node->id();

Returns the node's unique, internal ID number.

=head2 connections()

	my $cnt = $node->connections();

Returns the count of incoming and outgoing connections of this node.
Self-loops count as two connections, so in the following example, node C<N>
has B<four> connections, but only B<three> edges:

	            +--+
	            v  |
	+---+     +------+     +---+
	| 1 | --> |  N   | --> | 2 |
	+---+     +------+     +---+

See also L<edges()>.

=head2 edges()

	my $edges = $node->edges();

Returns a list of all the edges (as L<Graph::Easy::Edge> objects) at this node,
in no particular order.

=head2 predecessors()

	my @pre = $node->predecessors();

Returns all nodes (as objects) that link to us.

=head2 has_predecessors()

	if ($node->has_predecessors())
	  {
	  ...
	  }

Returns true if the node has one or more predecessors. Will return true for
nodes with selfloops.

=head2 successors()

	my @suc = $node->successors();

Returns all nodes (as objects) that we are linking to.

=head2 sorted_successors()

	my @suc = $node->sorted_successors();

Return successors of the node sorted by their chain value
(e.g. successors with more successors first). 

=head2 has_as_successor()

	if ($node->has_as_successor($other))
	  {
	  ...
	  }

Returns true if C<$other> ( a node or group) is a successor of node, that is if
there is an edge leading from node to C<$other>.

=head2 has_as_predecessor()

	if ($node->has_as_predecessor($other))
	  {
	  ...
	  }

Returns true if the node has C<$other> (a group or node) as predecessor, that
is if there is an edge leading from C<$other> to node.

=head2 edges_to()

	my @edges = $node->edges_to($other_node);

Returns all the edges (as objects) that start at C<< $node >> and go to
C<< $other_node >>.

=head2 shared_edges()

	my @edges = $node->shared_edges();

Return a list of all edges starting/ending at this node, that share a port
with another edge.

=head2 nodes_sharing_start()

	my @nodes = $node->nodes_sharing_start($side, $port);

Return a list of unique nodes that share a start point with an edge
from this node, on the specified side (absolute) and port number.

=head2 nodes_sharing_end()

	my @nodes = $node->nodes_sharing_end($side, $port);

Return a list of unique nodes that share an end point with an edge
from this node, on the specified side (absolute) and port number.

=head2 edges_at_port()

	my @edges = $node->edges_to('start', 'south', '0');

Returns all the edge objects that share the same C<start> or C<end>
port at the specified side and port number. The side must be
one of C<south>, C<north>, C<west> or C<east>. The port number
must be positive.

=head2 incoming()

	my @edges = $node->incoming();

Return all edges that end at this node.

=head2 outgoing()

	my @edges = $node->outgoing();

Return all edges that start at this node.

=head2 add_to_group()

	$node->add_to_group( $group );

Put the node into this group.

=head2 group()

	my $group = $node->group();

Return the group this node belongs to, or undef.

=head2 parent()

	my $parent = $node->parent();

Returns the parent object of the node, which is either the group the node belongs
to, or the graph.

=head2 origin()

	my $origin_node = $node->origin();

Returns the node this node is relativ to, or undef otherwise.

=head2 relative_to()

	$node->relative_to($parent, $dx, $dy);

Sets itself relativ to C<$parent> with the offset C<$dx,$dy>.

=head2 shape()

	my $shape = $node->shape();

Returns the shape of the node as string, defaulting to 'rect'. 

=head2 angle()

	my $angle = $self->rotation();

Return the node's rotation, based on the C<rotate> attribute, and
in case this is relative, on the node's flow.

=head2 flow()

	my $flow = $node->flow();

Returns the outgoing flow for this node as absolute direction in degrees.

The value is computed from the incoming flow (or the general flow as
default) and the flow attribute of this node.

=head2 _extra_params()

	my $extra_params = $node->_extra_params();

The return value of that method is added as extra params to the
HTML tag for a node when as_html() is called. Returns the empty
string by default, and can be overridden in subclasses. See also
L<use_class()>.

Overridden method should return a text with a leading space, or the
empty string.

Example:

	package Graph::Easy::MyNode;
	use base qw/Graph::Easy::Node/;

	sub _extra_params
	  {
	  my $self = shift;

	  ' ' . 'onmouseover="alert(\'' . $self->name() . '\');"'; 
	  }

	1;

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2007 by Tels L<http://bloodgate.com>.

See the LICENSE file for more details.

=cut
#############################################################################
# (c) by Tels 2004. Part of Graph::Easy. An anonymous (invisible) node.
#
#############################################################################

package Graph::Easy::Node::Anon;

use Graph::Easy::Node;

@ISA = qw/Graph::Easy::Node/;
$VERSION = '0.11';

use strict;

sub _init
  {
  my $self = shift;

  $self->SUPER::_init(@_);

  $self->{name} = '#' . $self->{id};
  $self->{class} = 'node.anon';

  $self->{att}->{label} = ' ';

  $self;
  }

sub _correct_size
  {
  my $self = shift;

  $self->{w} = 3;
  $self->{h} = 3;

  $self;
  }

sub attributes_as_txt
  {
  my $self = shift;

  $self->SUPER::attributes_as_txt( {
     node => {
       label => undef,
       shape => undef,
       class => undef,
       } } );
  }

sub as_pure_txt
  {
  '[ ]';
  }

sub _as_part_txt
  {
  '[ ]';
  }

sub as_txt
  {
  my $self = shift;

  '[ ]' . $self->attributes_as_txt();
  }

sub text_styles_as_css
  {
  '';
  }

sub is_anon
  {
  # is an anon node
  1;
  }

1;
__END__

=head1 NAME

Graph::Easy::Node::Anon - An anonymous, invisible node in Graph::Easy

=head1 SYNOPSIS

	use Graph::Easy::Node::Anon;

	my $anon = Graph::Easy::Node::Anon->new();

=head1 DESCRIPTION

A C<Graph::Easy::Node::Anon> represents an anonymous, invisible node.
These can be used to let edges start and end "nowhere".

The syntax in the Graph::Easy textual description language looks like this:

	[ ] -> [ Bonn ] -> [ ]

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Graph::Easy::Node>.

=head1 AUTHOR

Copyright (C) 2004 - 2006 by Tels L<http://bloodgate.com>.

See the LICENSE file for more details.

=cut
#############################################################################
# (c) by Tels 2004 - 2005. An empty filler cell. Part of Graph::Easy.
#
#############################################################################

package Graph::Easy::Node::Cell;

use Graph::Easy::Node;

@ISA = qw/Graph::Easy::Node/;
$VERSION = '0.10';

use strict;

#############################################################################

sub _init
  {
  # generic init, override in subclasses
  my ($self,$args) = @_;
  
  $self->{class} = '';
  $self->{name} = '';
  
  $self->{x} = 0;
  $self->{y} = 0;

  # default: belongs to no node
  $self->{node} = undef;

  foreach my $k (keys %$args)
    {
    if ($k !~ /^(node|graph|x|y)\z/)
      {
      require Carp;
      Carp::confess ("Invalid argument '$k' passed to Graph::Easy::Node::Cell->new()");
      }
    $self->{$k} = $args->{$k};
    }
 
  $self;
  }

sub _correct_size
  {
  my $self = shift;

  $self->{w} = 0;
  $self->{h} = 0;

  $self;
  }

sub node
  {
  # return the node this cell belongs to
  my $self = shift;

  $self->{node};
  }

sub as_ascii
  {
  '';
  }

sub as_html
  {
  '';
  }

sub group
  {
  my $self = shift;

  $self->{node}->group();
  }

1;
__END__

=head1 NAME

Graph::Easy::Node::Cell - An empty filler cell

=head1 SYNOPSIS

        use Graph::Easy;
        use Graph::Easy::Edge;

	my $graph = Graph::Easy->new();

	my $node = $graph->add_node('A');

	my $path = Graph::Easy::Node::Cell->new(
	  graph => $graph, node => $node,
	);

	...

	print $graph->as_ascii();

=head1 DESCRIPTION

A C<Graph::Easy::Node::Cell> is used to reserve a cell in the grid for nodes
that occupy more than one cell.

You should not need to use this class directly.

=head1 METHODS

=head2 error()

	$last_error = $cell->error();

	$cvt->error($error);			# set new messags
	$cvt->error('');			# clear error

Returns the last error message, or '' for no error.

=head2 node()

	my $node = $cell->node();

Returns the node this filler cell belongs to.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2005 by Tels L<http://bloodgate.com>.

See the LICENSE file for more details.

=cut
#############################################################################
# An empty, borderless cell. Part of Graph::Easy.
#
#############################################################################

package Graph::Easy::Node::Empty;

use Graph::Easy::Node;

@ISA = qw/Graph::Easy::Node/;
$VERSION = '0.06';

use strict;

#############################################################################

sub _init
  {
  # generic init, override in subclasses
  my ($self,$args) = @_;

  $self->SUPER::_init($args);
  
  $self->{class} = 'node.empty';

  $self;
  }

sub _correct_size
  {
  my $self = shift;

  $self->{w} = 3;
  $self->{h} = 3;

  $self;
  }

1;
__END__

=head1 NAME

Graph::Easy::Node::Empty - An empty, borderless cell in a node cluster

=head1 SYNOPSIS

	my $cell = Graph::Easy::Node::Empty->new();

=head1 DESCRIPTION

A C<Graph::Easy::Node::Empty> represents a borderless, empty cell in
a node cluster. It is mainly used to have an object to render collapsed
borders in ASCII output.

You should not need to use this class directly.

=head1 SEE ALSO

L<Graph::Easy::Node>.

=head1 AUTHOR

Copyright (C) 2004 - 2007 by Tels L<http://bloodgate.com>.

See the LICENSE file for more details.

=cut
#############################################################################
# An edge connecting two nodes in Graph::Easy.
#
#############################################################################

package Graph::Easy::Edge;

use Graph::Easy::Node;
@ISA = qw/Graph::Easy::Node/;		# an edge is just a special node
$VERSION = '0.31';

use strict;

use constant isa_cell => 1;

#############################################################################

sub _init
  {
  # generic init, override in subclasses
  my ($self,$args) = @_;
  
  $self->{class} = 'edge';

  # leave this unitialized until we need it
  # $self->{cells} = [ ];

  foreach my $k (keys %$args)
    {
    if ($k !~ /^(label|name|style)\z/)
      {
      require Carp;
      Carp::confess ("Invalid argument '$k' passed to Graph::Easy::Node->new()");
      }
    my $n = $k; $n = 'label' if $k eq 'name';

    $self->{att}->{$n} = $args->{$k};
    }

  $self;
  }

#############################################################################
# accessor methods

sub bidirectional
  {
  my $self = shift;
 
  if (@_ > 0)
    {
    my $old = $self->{bidirectional} || 0;
    $self->{bidirectional} = $_[0] ? 1 : 0; 

    # invalidate layout?
    $self->{graph}->{score} = undef if $old != $self->{bidirectional} && ref($self->{graph});
    }

  $self->{bidirectional};
  }

sub undirected
  {
  my $self = shift;

  if (@_ > 0)
    {
    my $old = $self->{undirected} || 0;
    $self->{undirected} = $_[0] ? 1 : 0; 

    # invalidate layout?
    $self->{graph}->{score} = undef if $old != $self->{undirected} && ref($self->{graph});
    }

  $self->{undirected};
  }

sub has_ports
  {
  my $self = shift;

  my $s_port = $self->{att}->{start} || $self->attribute('start');

  return 1 if $s_port ne '';

  my $e_port = $self->{att}->{end} || $self->attribute('end');

  return 1 if $e_port ne '';

  0;
  }

sub start_port
  {
  # return the side and portnumber if the edge has a shared source port
  # undef for none
  my $self = shift;

  my $s = $self->{att}->{start} || $self->attribute('start');
  return undef if !defined $s || $s !~ /,/;	# "south, 0" => ok, "south" => no

  return (split /\s*,\s*/, $s) if wantarray;

  $s =~ s/\s+//g;		# remove spaces to normalize "south, 0" to "south,0"
  $s;
  }

sub end_port
  {
  # return the side and portnumber if the edge has a shared source port
  # undef for none
  my $self = shift;

  my $s = $self->{att}->{end} || $self->attribute('end');
  return undef if !defined $s || $s !~ /,/;	# "south, 0" => ok, "south" => no

  return split /\s*,\s*/, $s if wantarray;

  $s =~ s/\s+//g;		# remove spaces to normalize "south, 0" to "south,0"
  $s;
  }

sub style
  {
  my $self = shift;

  $self->{att}->{style} || $self->attribute('style');
  }

sub name
  {
  # returns actually the label
  my $self = shift;

  $self->{att}->{label} || '';
  }

#############################################################################
# cell management - used by the cell-based layouter

sub _cells
  {
  # return all the cells this edge currently occupies
  my $self = shift;

  $self->{cells} = [] unless defined $self->{cells};

  @{$self->{cells}};
  }

sub _clear_cells
  { 
  # remove all belonging cells
  my $self = shift;

  $self->{cells} = [];

  $self;
  }

sub _unplace
  {
  # Take an edge, and remove all the cells it covers from the cells area
  my ($self, $cells) = @_;

  print STDERR "# clearing path from $self->{from}->{name} to $self->{to}->{name}\n" if $self->{debug};

  for my $key (@{$self->{cells}})
    {
    # XXX TODO: handle crossed edges differently (from CROSS => HOR or VER)
    # free in our cells area
    delete $cells->{$key};
    }

  $self->clear_cells();

  $self;
  }

sub _distance
  {
  # estimate the distance from SRC to DST node
  my ($self) = @_;

  my $src = $self->{from};
  my $dst = $self->{to};

  # one of them not yet placed?
  return 100000 unless defined $src->{x} && defined $dst->{x};

  my $cells = $self->{graph}->{cells};

  # get all the starting positions
  # distance = 1: slots, generate starting types, the direction is shifted
  # by 90° counter-clockwise

  my @start = $src->_near_places($cells, 1, undef, undef, $src->_shift(-90) );

  # potential stop positions
  my @stop = $dst->_near_places($cells, 1);		# distance = 1: slots

  my ($s_p,@ss_p) = $self->port('start');
  my ($e_p,@ee_p) = $self->port('end');

  # the edge has a port description, limiting the start places
  @start = $src->_allowed_places( \@start, $src->_allow( $s_p, @ss_p ), 3)
    if defined $s_p;

  # the edge has a port description, limiting the stop places
  @stop = $dst->_allowed_places( \@stop, $dst->_allow( $e_p, @ee_p ), 3)
    if defined $e_p;

  my $stop = scalar @stop;

  return 0 unless @stop > 0 && @start > 0;	# no free slots on one node?

  my $lowest;

  my $i = 0;
  while ($i < scalar @start)
    {
    my $sx = $start[$i]; my $sy = $start[$i+1]; $i += 2;

    # for each start point, calculate the distance to each stop point, then use
    # the smallest as value

    for (my $u = 0; $u < $stop; $u += 2)
      {
      my $dist = Graph::Easy::_astar_distance($sx,$sy, $stop[$u], $stop[$u+1]);
      $lowest = $dist if !defined $lowest || $dist < $lowest;
      }
    }

  $lowest;
  }

sub _add_cell
  {
  # add a cell to the list of cells this edge covers. If $after is a ref
  # to a cell, then the new cell will be inserted right after this cell.
  # if after is defined, but not a ref, the new cell will be inserted
  # at the specified position.
  my ($self, $cell, $after, $before) = @_;
 
  $self->{cells} = [] unless defined $self->{cells};
  my $cells = $self->{cells};

  # if both are defined, but belong to different edges, just ignore $before:
  $before = undef if ref($before) && $before->{edge} != $self;
  $after = undef if ref($after) && $after->{edge} != $self;
  if (!defined $after && ref($before))
    {
    $after = $before; $before = undef;
    }

  if (defined $after)
    {
    # insert the new cell right after $after
    my $ofs = $after;
    if (ref($after) && !ref($before))
      {
      # insert after $after
      $ofs = 1;
      for my $cell (@$cells)
        {
        last if $cell == $after;
        $ofs++; 
        }
      }
    elsif (ref($after) && ref($before))
      {
      # insert between after and before (or before/after for "reversed edges)
      $ofs = 0;
      my $found = 0;
      while ($ofs < scalar @$cells - 1)		# 0,1,2,3 => 0 .. 2
        {
        my $c1 = $cells->[$ofs];
        my $c2 = $cells->[$ofs+1];
	$ofs++;
        $found++, last if (($c1 == $after && $c2 == $before) ||
                 ($c1 == $before && $c2 == $after));
        }
      if (!$found)
	{
        # XXX TODO: last effort

        # insert after $after
        $ofs = 1;
        for my $cell (@$cells)
          {
          last if $cell == $after;
          $ofs++; 
          }
        $found++;
	}
      $self->_croak("Could not find $after and $before") unless $found;
      }
    splice (@$cells, $ofs, 0, $cell);
    } 
  else
    {
    # insert new cell at the end
    push @$cells, $cell;
    }

  $cell->_update_boundaries();

  $self;
  }

#############################################################################

sub from
  {
  my $self = shift;

  $self->{from};
  }

sub to
  {
  my $self = shift;

  $self->{to};
  }

sub nodes
  {
  my $self = shift;

  ($self->{from}, $self->{to});
  }

sub start_at
  {
  # move the edge's start point from the current node to the given node
  my ($self, $node) = @_;

  # if not a node yet, or not part of this graph, make into one proper node
  $node = $self->{graph}->add_node($node);

  $self->_croak("start_at() needs a node object, but got $node")
    unless ref($node) && $node->isa('Graph::Easy::Node');

  # A => A => nothing to do
  return $node if $self->{from} == $node;

  # delete self at A
  delete $self->{from}->{edges}->{ $self->{id} };

  # set "from" to B
  $self->{from} = $node;

  # add to B
  $self->{from}->{edges}->{ $self->{id} } = $self;

  # invalidate layout
  $self->{graph}->{score} = undef if ref($self->{graph});

  # return new start point
  $node;
  }

sub end_at
  {
  # move the edge's end point from the current node to the given node
  my ($self, $node) = @_;

  # if not a node yet, or not part of this graph, make into one proper node
  $node = $self->{graph}->add_node($node);

  $self->_croak("start_at() needs a node object, but got $node")
    unless ref($node) && $node->isa('Graph::Easy::Node');

  # A => A => nothing to do
  return $node if $self->{to} == $node;

  # delete self at A
  delete $self->{to}->{edges}->{ $self->{id} };

  # set "to" to B
  $self->{to} = $node;

  # add to node B
  $self->{to}->{edges}->{ $self->{id} } = $self;

  # invalidate layout
  $self->{graph}->{score} = undef if ref($self->{graph});

  # return new end point
  $node;
  }

sub edge_flow
  {
  # return the flow at this edge  or '' if the edge itself doesn't have a flow
  my $self = shift;

  # our flow comes from ourselves
  my $flow = $self->{att}->{flow};
  $flow = $self->raw_attribute('flow') unless defined $flow;

  $flow;
  }

sub flow
  {
  # return the flow at this edge (including inheriting flow from node)
  my ($self) = @_;

  # print STDERR "# flow from $self->{from}->{name} to $self->{to}->{name}\n";

  # our flow comes from ourselves
  my $flow = $self->{att}->{flow};
  # or maybe our class
  $flow = $self->raw_attribute('flow') unless defined $flow;

  # if the edge doesn't have a flow, maybe the node has a default out flow
  $flow = $self->{from}->{att}->{flow} if !defined $flow;

  # if that didn't work out either, use the parents flows
  $flow = $self->parent()->attribute('flow') if !defined $flow; 
  # or finally, the default "east":
  $flow = 90 if !defined $flow;

  # absolute flow does not depend on the in-flow, so can return early
  return $flow if $flow =~ /^(0|90|180|270)\z/;

  # in-flow comes from our "from" node
  my $in = $self->{from}->flow();

# print STDERR "# in: $self->{from}->{name} = $in\n";

  my $out = $self->{graph}->_flow_as_direction($in,$flow);
  $out;
  }

sub port
  {
  my ($self, $which) = @_;

  $self->_croak("'$which' must be one of 'start' or 'end' in port()") unless $which =~ /^(start|end)/;

  # our flow comes from ourselves
  my $sp = $self->attribute($which); 

  return (undef,undef) unless defined $sp && $sp ne '';

  my ($side, $port) = split /\s*,\s*/, $sp;

  # if absolut direction, return as is
  my $s = Graph::Easy->_direction_as_side($side);

  if (defined $s)
    {
    my @rc = ($s); push @rc, $port if defined $port;
    return @rc;
    }

  # in_flow comes from our "from" node
  my $in = 90; $in = $self->{from}->flow() if ref($self->{from});

  # turn left in "south" etc:
  $s = Graph::Easy->_flow_as_side($in,$side);

  my @rc = ($s); push @rc, $port if defined $port;
  @rc;
  }

sub flip
  {
  # swap from and to for this edge
  my ($self) = @_;

  ($self->{from}, $self->{to}) = ($self->{to}, $self->{from});

  # invalidate layout
  $self->{graph}->{score} = undef if ref($self->{graph});

  $self;
  }

sub as_ascii
  {
  my ($self, $x,$y) = @_;

  # invisible nodes, or very small ones
  return '' if $self->{w} == 0 || $self->{h} == 0;

  my $fb = $self->_framebuffer($self->{w}, $self->{h});

  ###########################################################################
  # "draw" the label into the framebuffer (e.g. the edge and the text)
  $self->_draw_label($fb, $x, $y, '');

  join ("\n", @$fb);
  }

sub as_txt
  {
  require Graph::Easy::As_ascii;

  _as_txt(@_);
  }

1;
__END__

=head1 NAME

Graph::Easy::Edge - An edge (a path connecting one ore more nodes)

=head1 SYNOPSIS

        use Graph::Easy;

	my $ssl = Graph::Easy::Edge->new(
		label => 'encrypted connection',
		style => 'solid',
	);
	$ssl->set_attribute('color', 'red');

	my $src = Graph::Easy::Node->new('source');

	my $dst = Graph::Easy::Node->new('destination');

	$graph = Graph::Easy->new();

	$graph->add_edge($src, $dst, $ssl);

	print $graph->as_ascii();

=head1 DESCRIPTION

A C<Graph::Easy::Edge> represents an edge between two (or more) nodes in a
simple graph.

Each edge has a direction (from source to destination, or back and forth),
plus a style (line width and style), colors etc. It can also have a label,
e.g. a text associated with it.

During the layout phase, each edge also contains a list of path-elements
(also called cells), which make up the path from source to destination.

=head1 METHODS

=head2 error()

	$last_error = $edge->error();

	$cvt->error($error);			# set new messags
	$cvt->error('');			# clear error

Returns the last error message, or '' for no error.

=head2 as_ascii()

	my $ascii = $edge->as_ascii();

Returns the edge as a little ascii representation.

=head2 as_txt()

	my $txt = $edge->as_txt();

Returns the edge as a little Graph::Easy textual representation.

=head2 label()

	my $label = $edge->label();

Returns the label (also known as 'name') of the edge.

=head2 name()

	my $label = $edge->name();

To make the interface more consistent, the C<name()> method of
an edge can also be called, and it will returned either the edge
label, or the empty string if the edge doesn't have a label.

=head2 style()

	my $style = $edge->style();

Returns the style of the edge, like 'solid', 'dotted', 'double', etc.

=head2 nodes()

	my @nodes = $edge->nodes();

Returns the source and target node that this edges connects as objects.

=head2 bidirectional()

	$edge->bidirectional(1);
	if ($edge->bidirectional())
	  {
	  }

Returns true if the edge is bidirectional, aka has arrow heads on both ends.
An optional parameter will set the bidirectional status of the edge.

=head2 undirected()

	$edge->undirected(1);
	if ($edge->undirected())
	  {
	  }

Returns true if the edge is undirected, aka has now arrow at all.
An optional parameter will set the undirected status of the edge.

=head2 has_ports()

	if ($edge->has_ports())
	  {
	  ...
	  }

Return true if the edge has restriction on the starting or ending
port, e.g. either the C<start> or C<end> attribute is set on
this edge. 

=head2 start_port()

	my $port = $edge->start_port();

Return undef if the edge does not have a fixed start port, otherwise
returns the port as "side, number", for example "south, 0".

=head2 end_port()

	my $port = $edge->end_port();

Return undef if the edge does not have a fixed end port, otherwise
returns the port as "side, number", for example "south, 0".

=head2 from()

	my $from = $edge->from();

Returns the node that this edge starts at. See also C<to()>.

=head2 to()

	my $to = $edge->to();

Returns the node that this edge leads to. See also C<from()>.

=head2 start_at()

	$edge->start_at($other);
	my $other = $edge->start_at('some node');

Set the edge's start point to the given node. If given a node name,
will add that node to the graph first.

Returns the new edge start point node.

=head2 end_at()

	$edge->end_at($other);
	my $other = $edge->end_at('some other node');

Set the edge's end point to the given node. If given a node name,
will add that node to the graph first.

Returns the new edge end point node.

=head2 flip()

	$edge->flip();

Swaps the C<start> and C<end> nodes on this edge, e.g. reverses the direction
of the edge.

X<transpose>

=head2 flow()

	my $flow = $edge->flow();

Returns the flow for this edge, honoring inheritance. An edge without
a specific flow set will inherit the flow from the node it comes from.

=head2 edge_flow()

	my $flow = $edge->edge_flow();

Returns the flow for this edge, or undef if it has none set on either
the object itself or its class.

=head2 port()

	my ($side, $number) = $edge->port('start');
	my ($side, $number) = $edge->port('end');

Return the side and port number where this edge starts or ends.

Returns undef for $side if the edge has no port restriction. The
returned side will be one absolute direction of C<east>, C<west>,
C<north> or C<south>, depending on the port restriction and
flow at that edge.

=head2 get_attributes()

        my $att = $object->get_attributes();

Return all effective attributes on this object (graph/node/group/edge) as
an anonymous hash ref. This respects inheritance and default values.

See also L<raw_attributes()>.

=head2 raw_attributes()

        my $att = $object->get_attributes();

Return all set attributes on this object (graph/node/group/edge) as
an anonymous hash ref. This respects inheritance, but does not include
default values for unset attributes.

See also L<get_attributes()>.

=head2 attribute related methods

You can call all the various attribute related methods like C<set_attribute()>,
C<get_attribute()>, etc. on an edge, too. For example:

	$edge->set_attribute('label', 'by train');
	my $attr = $edge->get_attributes();
	my $raw_attr = $edge->raw_attributes();

You can find more documentation in L<Graph::Easy>.

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2008 by Tels L<http://bloodgate.com>.

See the LICENSE file for more details.

=cut
#############################################################################
# Part of Graph::Easy.
#
#############################################################################

package Graph::Easy::Edge::Cell;

use strict;
use Graph::Easy::Edge;
use Graph::Easy::Attributes;
require Exporter;

use vars qw/$VERSION @EXPORT_OK @ISA/;
@ISA = qw/Exporter Graph::Easy::Edge/;

$VERSION = '0.29';

use Scalar::Util qw/weaken/;

#############################################################################

# The different cell types:
use constant {
  EDGE_CROSS	=> 0,		# +	crossing lines
  EDGE_HOR	=> 1,	 	# --	horizontal line
  EDGE_VER	=> 2,	 	# |	vertical line

  EDGE_N_E	=> 3,		# |_	corner (N to E)
  EDGE_N_W	=> 4,		# _|	corner (N to W)
  EDGE_S_E	=> 5,		# ,-	corner (S to E)
  EDGE_S_W	=> 6,		# -,	corner (S to W)

# Joints:
  EDGE_S_E_W	=> 7,		# -,-	three-sided corner (S to W/E)
  EDGE_N_E_W	=> 8,		# -'-	three-sided corner (N to W/E)
  EDGE_E_N_S	=> 9,		#  |-   three-sided corner (E to S/N)
  EDGE_W_N_S	=> 10,		# -|	three-sided corner (W to S/N)

  EDGE_HOLE	=> 11,		# 	a hole (placeholder for the "other"
				#	edge in a crossing section
				#	Holes are inserted in the layout stage
				#	and removed in the optimize stage, before
				#	rendering occurs.

# these loop types must come last
  EDGE_N_W_S	=> 12,		# v--+  loop, northwards
  EDGE_S_W_N	=> 13,		# ^--+  loop, southwards
  EDGE_E_S_W	=> 14,		# [_    loop, westwards
  EDGE_W_S_E	=> 15,		# _]    loop, eastwards

  EDGE_MAX_TYPE		=> 15, 	# last valid type
  EDGE_LOOP_TYPE	=> 12, 	# first LOOP type

# Flags:
  EDGE_START_E		=> 0x0100,	# start from East	(sorted ESWN)
  EDGE_START_S		=> 0x0200,	# start from South
  EDGE_START_W		=> 0x0400,	# start from West
  EDGE_START_N		=> 0x0800,	# start from North

  EDGE_END_W		=> 0x0010,	# end points to West	(sorted WNES)
  EDGE_END_N		=> 0x0020,	# end points to North
  EDGE_END_E		=> 0x0040,	# end points to East
  EDGE_END_S		=> 0x0080,	# end points to South

  EDGE_LABEL_CELL	=> 0x1000,	# this cell carries the label
  EDGE_SHORT_CELL	=> 0x2000,	# a short edge pice (for filling)

  EDGE_ARROW_MASK	=> 0x0FF0,	# mask out the end/start type
  EDGE_START_MASK	=> 0x0F00,	# mask out the start type
  EDGE_END_MASK		=> 0x00F0,	# mask out the end type
  EDGE_TYPE_MASK	=> 0x000F,	# mask out the basic cell type
  EDGE_FLAG_MASK	=> 0xFFF0,	# mask out the flags
  EDGE_MISC_MASK	=> 0xF000,	# mask out the misc. flags
  EDGE_NO_M_MASK	=> 0x0FFF,	# anything except the misc. flags

  ARROW_RIGHT	=> 0,
  ARROW_LEFT	=> 1,
  ARROW_UP	=> 2,
  ARROW_DOWN	=> 3,
  };

use constant {
  EDGE_ARROW_HOR	=> EDGE_END_E() + EDGE_END_W(),
  EDGE_ARROW_VER	=> EDGE_END_N() + EDGE_END_S(),

# shortcuts to not need to write EDGE_HOR + EDGE_START_W + EDGE_END_E
  EDGE_SHORT_E => EDGE_HOR + EDGE_END_E + EDGE_START_W,		# |-> start/end at this cell
  EDGE_SHORT_S => EDGE_VER + EDGE_END_S + EDGE_START_N,		# v   start/end at this cell
  EDGE_SHORT_W => EDGE_HOR + EDGE_END_W + EDGE_START_E,		# <-| start/end at this cell
  EDGE_SHORT_N => EDGE_VER + EDGE_END_N + EDGE_START_S,		# ^   start/end at this cell

  EDGE_SHORT_BD_EW => EDGE_HOR + EDGE_END_E + EDGE_END_W,	# <-> start/end at this cell
  EDGE_SHORT_BD_NS => EDGE_VER + EDGE_END_S + EDGE_END_N,	# ^
								# | start/end at this cell
								# v
  EDGE_SHORT_UN_EW => EDGE_HOR + EDGE_START_E + EDGE_START_W,	# --
  EDGE_SHORT_UN_NS => EDGE_VER + EDGE_START_S + EDGE_START_N,   # |

  EDGE_LOOP_NORTH  => EDGE_N_W_S + EDGE_END_S + EDGE_START_N + EDGE_LABEL_CELL,
  EDGE_LOOP_SOUTH  => EDGE_S_W_N + EDGE_END_N + EDGE_START_S + EDGE_LABEL_CELL,
  EDGE_LOOP_WEST   => EDGE_W_S_E + EDGE_END_E + EDGE_START_W + EDGE_LABEL_CELL,
  EDGE_LOOP_EAST   => EDGE_E_S_W + EDGE_END_W + EDGE_START_E + EDGE_LABEL_CELL,
  };

#############################################################################

@EXPORT_OK = qw/
  EDGE_START_E
  EDGE_START_W
  EDGE_START_N
  EDGE_START_S

  EDGE_END_E
  EDGE_END_W	
  EDGE_END_N
  EDGE_END_S

  EDGE_SHORT_E
  EDGE_SHORT_W	
  EDGE_SHORT_N
  EDGE_SHORT_S

  EDGE_SHORT_BD_EW
  EDGE_SHORT_BD_NS

  EDGE_SHORT_UN_EW
  EDGE_SHORT_UN_NS

  EDGE_HOR
  EDGE_VER
  EDGE_CROSS
  EDGE_HOLE

  EDGE_N_E
  EDGE_N_W
  EDGE_S_E
  EDGE_S_W

  EDGE_S_E_W
  EDGE_N_E_W
  EDGE_E_N_S
  EDGE_W_N_S	

  EDGE_LOOP_NORTH
  EDGE_LOOP_SOUTH
  EDGE_LOOP_EAST
  EDGE_LOOP_WEST

  EDGE_N_W_S
  EDGE_S_W_N
  EDGE_E_S_W
  EDGE_W_S_E

  EDGE_TYPE_MASK
  EDGE_FLAG_MASK
  EDGE_ARROW_MASK
  
  EDGE_START_MASK
  EDGE_END_MASK
  EDGE_MISC_MASK

  EDGE_LABEL_CELL
  EDGE_SHORT_CELL

  EDGE_NO_M_MASK

  ARROW_RIGHT
  ARROW_LEFT
  ARROW_UP
  ARROW_DOWN
  /;

my $edge_types = {
  EDGE_HOR() => 'horizontal',
  EDGE_VER() => 'vertical',

  EDGE_CROSS() => 'crossing',

  EDGE_N_E() => 'north/east corner',
  EDGE_N_W() => 'north/west corner',
  EDGE_S_E() => 'south/east corner',
  EDGE_S_W() => 'south/west corner',

  EDGE_S_E_W() => 'joint south to east/west',
  EDGE_N_E_W() => 'joint north to east/west',
  EDGE_E_N_S() => 'joint east to north/south',
  EDGE_W_N_S() => 'joint west to north/south',

  EDGE_N_W_S() => 'selfloop, northwards',
  EDGE_S_W_N() => 'selfloop, southwards',
  EDGE_E_S_W() => 'selfloop, eastwards',
  EDGE_W_S_E() => 'selfloop, westwards',
  };

my $flag_types = {
  EDGE_LABEL_CELL() => 'labeled',
  EDGE_SHORT_CELL() => 'short',

  EDGE_START_E() => 'starting east',
  EDGE_START_W() => 'starting west',
  EDGE_START_N() => 'starting north',
  EDGE_START_S() => 'starting south',

  EDGE_END_E() => 'ending east',
  EDGE_END_W() => 'ending west',
  EDGE_END_N() => 'ending north',
  EDGE_END_S() => 'ending south',
  };

use constant isa_cell => 1;

sub edge_type
  {
  # convert edge type number to some descriptive text
  my $type = shift;

  my $flags = $type & EDGE_FLAG_MASK;
  $type &= EDGE_TYPE_MASK;

  my $t = $edge_types->{$type} || ('unknown edge type #' . $type);

  $flags &= EDGE_FLAG_MASK;

  my $mask = 0x0010;
  while ($mask < 0xFFFF)
    {
    my $tf = $flags & $mask; $mask <<= 1;
    $t .= ", $flag_types->{$tf}" if $tf != 0;
    }

  $t;
  }

#############################################################################

sub _init
  {
  # generic init, override in subclasses
  my ($self,$args) = @_;
  
  $self->{type} = EDGE_SHORT_E();	# -->
  $self->{style} = 'solid';
  
  $self->{x} = 0;
  $self->{y} = 0;
  $self->{w} = undef;
  $self->{h} = 3;

  foreach my $k (keys %$args)
    {
    # don't store "after" and "before"
    next unless $k =~ /^(graph|edge|x|y|type)\z/;
    $self->{$k} = $args->{$k};
    }

  $self->_croak("Creating edge cell without a parent edge object")
    unless defined $self->{edge};
  $self->_croak("Creating edge cell without a type")
    unless defined $self->{type};

  # take over settings from edge
  $self->{style} = $self->{edge}->style();
  $self->{class} = $self->{edge}->class();
  $self->{graph} = $self->{edge}->{graph};
  $self->{group} = $self->{edge}->{group};
  weaken($self->{graph});
  weaken($self->{group});
  $self->{att} = $self->{edge}->{att};

  # register ourselves at this edge
  $self->{edge}->_add_cell ($self, $args->{after}, $args->{before});

  $self;
  }

sub arrow_count
  {
  # return 0, 1 or 2, depending on the number of end points
  my $self = shift;

  return 0 if $self->{edge}->{undirected};

  my $count = 0;
  my $type = $self->{type};
  $count ++ if ($type & EDGE_END_N) != 0;
  $count ++ if ($type & EDGE_END_S) != 0;
  $count ++ if ($type & EDGE_END_W) != 0;
  $count ++ if ($type & EDGE_END_E) != 0;
  if ($self->{edge}->{bidirectional})
    {
    $count ++ if ($type & EDGE_START_N) != 0;
    $count ++ if ($type & EDGE_START_S) != 0;
    $count ++ if ($type & EDGE_START_W) != 0;
    $count ++ if ($type & EDGE_START_E) != 0;
    }
  $count;
  }

sub _make_cross
  {
  # Upgrade us to a cross-section.
  my ($self, $edge, $flags) = @_;
  
  my $type = $self->{type} & EDGE_TYPE_MASK;
    
  $self->_croak("Trying to cross non hor/ver piece at $self->{x},$self->{y}")
    if (($type != EDGE_HOR) && ($type != EDGE_VER));

  $self->{color} = $self->get_color_attribute('color');
  $self->{style_ver} = $edge->style();
  $self->{color_ver} = $edge->get_color_attribute('color');

  # if we are the VER piece, switch styles around
  if ($type == EDGE_VER)
    {
    ($self->{style_ver}, $self->{style}) = ($self->{style},$self->{style_ver});
    ($self->{color_ver}, $self->{color}) = ($self->{color},$self->{color});
    }

  $self->{type} = EDGE_CROSS + ($flags || 0);

  $self;
  }

sub _make_joint
  {
  # Upgrade us to a joint
  my ($self, $edge, $new_type) = @_;
  
  my $type = $self->{type} & EDGE_TYPE_MASK;

  $self->_croak("Trying to join non hor/ver piece (type: $type) at $self->{x},$self->{y}")
     if $type >= EDGE_S_E_W;

  $self->{color} = $self->get_color_attribute('color');
  $self->{style_ver} = $edge->style();
  $self->{color_ver} = $edge->get_color_attribute('color');

  # if we are the VER piece, switch styles around
  if ($type == EDGE_VER)
    {
    ($self->{style_ver}, $self->{style}) = ($self->{style},$self->{style_ver});
    ($self->{color_ver}, $self->{color}) = ($self->{color},$self->{color});
    }

  print STDERR "# creating joint at $self->{x}, $self->{y} with new type $new_type (old $type)\n"
    if $self->{graph}->{debug};

  $self->{type} = $new_type;

  $self;
  }

#############################################################################
# conversion to HTML

my $edge_end_north = 
   ' <td colspan=2 class="##class## eb" style="##bg####ec##">&nbsp;</td>' . "\n" .
   ' <td colspan=2 class="##class## eb" style="##bg####ec##"><span class="su">^</span></td>' . "\n";
my $edge_end_south = 
   ' <td colspan=2 class="##class## eb" style="##bg####ec##">&nbsp;</td>' . "\n" .
   ' <td colspan=2 class="##class## eb" style="##bg####ec##"><span class="sv">v</span></td>' . "\n";

my $edge_empty_row =
   ' <td colspan=4 class="##class## eb"></td>';

my $edge_arrow_west_upper = 
   '<td rowspan=2 class="##class## eb" style="##ec####bg##"><span class="shl">&lt;</span></td>' . "\n";
my $edge_arrow_west_lower = 
   '<td rowspan=2 class="##class## eb">&nbsp;</td>' . "\n";

my $edge_arrow_east_upper = 
   '<td rowspan=2 class="##class## eb" style="##ec####bg##"><span class="sh">&gt;</span></td>' . "\n";
my $edge_arrow_east_lower =
   '<td rowspan=2 class="##class## eb"></td>' . "\n";

my $edge_html = {

  # The "&nbsp;" in empty table cells with borders are here to make IE display
  # the border. I so hate browser bugs :-(

  EDGE_S_E() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>',
    '',
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    '',
   ],

  EDGE_S_E() + EDGE_START_E() + EDGE_END_S() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td rowspan=4 class="##class## el"></td>',
    '',
    ' <td colspan=2 class="##class## eb"></td>'. "\n" .
    ' <td class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    $edge_end_south,
   ],

  EDGE_S_E() + EDGE_START_E() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td rowspan=4 class="##class## el"></td>',
    '',
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    '',
   ],

  EDGE_S_E() + EDGE_END_E() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td rowspan=4 class="##class##"##edgecolor##><span class="sa">&gt;</span></td>',
    '',
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>'. "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    '',
   ],

  EDGE_S_E() + EDGE_START_S() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>',
    '',
    ' <td colspan=2 class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>' . "\n",
    $edge_empty_row,
   ],

  EDGE_S_E() + EDGE_START_S() + EDGE_END_E() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>'.
    ' <td rowspan=4 class="##class##"##edgecolor##><span class="sa">&gt;</span></td>',
    '',
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>'. "\n" .
    ' <td class="##class## eb" style="border-left: ##border##;">&nbsp;</td>' . "\n",
    ' <td class="##class## eb"></td>',
   ],

  EDGE_S_E() + EDGE_END_S() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>',
    '',
    ' <td colspan=2 class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>' . "\n",
    $edge_end_south,
   ],

  EDGE_S_E() + EDGE_END_S() + EDGE_END_E() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td rowspan=4 class="##class## ha"##edgecolor##><span class="sa">&gt;</span></td>',
    '',
    ' <td colspan=2 class="##class## eb"></td>'. "\n" .
    ' <td class="##class## eb" style="border-left: ##border##;">&nbsp;</td>' . "\n",
    ' <td colspan=3 class="##class## v"##edgecolor##>v</td>',
   ],

  ###########################################################################
  ###########################################################################
  # S_W

  EDGE_S_W() => [
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>',
    '',
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    '',
   ],

  EDGE_S_W() + EDGE_START_W() => [
    ' <td rowspan=2 class="##class## el"></td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>',
    '',
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    '',
   ],

  EDGE_S_W() + EDGE_END_W() => [
    ' <td rowspan=2 class="##class## va"##edgecolor##><span class="shl">&lt;</span></td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>',
    '',
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    '',
   ],

  EDGE_S_W() + EDGE_START_S() => [
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>',
    '',
    ' <td colspan=2 class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    $edge_empty_row,
   ],

  EDGE_S_W() + EDGE_END_S() => [
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>',
    '',
    ' <td colspan=2 class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    $edge_end_south,
   ],

  EDGE_S_W() + EDGE_START_W() + EDGE_END_S() => [
    ' <td rowspan=2 class="##class## el"></td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>',
    '',
    ' <td colspan=2 class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    $edge_end_south,
   ],

  EDGE_S_W() + EDGE_START_S() + EDGE_END_W() => [
    ' <td rowspan=3 class="##class## sh"##edgecolor##>&lt;</td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>',
    '',
    ' <td class="##class## eb"></td>'. "\n" .
    ' <td colspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    $edge_empty_row,
   ],

  ###########################################################################
  ###########################################################################
  # N_W

  EDGE_N_W() => [
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    '',
    ' <td colspan=4 rowspan=2 class="##class## eb"></td>',
    '',
   ],

  EDGE_N_W() + EDGE_START_N() => [
    $edge_empty_row,
    ' <td colspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    '',
    ' <td colspan=4 rowspan=2 class="##class## eb"></td>',
   ],

  EDGE_N_W() + EDGE_END_N() => [
    $edge_end_north,
    ' <td colspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    ' <td colspan=4 rowspan=2 class="##class## eb"></td>',
    '',
   ],

  EDGE_N_W() + EDGE_END_N() + EDGE_START_W() => [
    $edge_end_north,
    ' <td rowspan=3 class="##class## eb"></td>'.
    ' <td class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>',
    ' <td colspan=4 rowspan=2 class="##class## eb"></td>',
    '',
   ],

  EDGE_N_W() + EDGE_START_W() => [
    ' <td rowspan=2 class="##class## el"></td>' . "\n" . 
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>' . "\n",
    '',
    ' <td colspan=4 rowspan=2 class="##class## eb"></td>',
    '',
   ],

  EDGE_N_W() + EDGE_END_W() => [
    ' <td rowspan=4 class="##class## sh"##edgecolor##>&lt;</td>' . "\n" . 
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##;">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##border##;">&nbsp;</td>' . "\n",
    '',
    ' <td colspan=3 rowspan=2 class="##class## eb"></td>',
    '',
   ],

  ###########################################################################
  ###########################################################################
  # N_E

  EDGE_N_E() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-bottom: ##border##; border-left: ##border##;">&nbsp;</td>',
    '',
    ' <td colspan=4 rowspan=2 class="##class## eb"></td>',
    '',
   ],

  EDGE_N_E() + EDGE_START_E() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##; border-left: ##border##;">&nbsp;</td>' . "\n" .
    ' <td rowspan=4 class="##class## el"></td>',
    '',
    ' <td colspan=3 rowspan=2 class="##class## eb"></td>',
    '',
   ],

  EDGE_N_E() + EDGE_END_E() => [
    ' <td colspan=2 rowspan=2 class="##class## eb"></td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-bottom: ##border##; border-left: ##border##;">&nbsp;</td>' . "\n" .
    ' <td rowspan=4 class="##class## va"##edgecolor##><span class="sa">&gt;</span></td>',
    '',
    ' <td colspan=3 rowspan=2 class="##class## eb"></td>',
    '',
   ],

  EDGE_N_E() + EDGE_END_E() + EDGE_START_N() => [
    $edge_empty_row,
    ' <td colspan=2 class="##class## eb"></td>' . "\n" .
    ' <td class="##class## eb" style="border-bottom: ##border##; border-left: ##border##;">&nbsp;</td>' . "\n" .
    ' <td rowspan=3 class="##class## va"##edgecolor##><span class="sa">&gt;</span></td>',
    ' <td colspan=3 rowspan=2 class="##class## eb"></td>',
    '',
   ],

  EDGE_N_E() + EDGE_START_E() + EDGE_END_N() => [
    $edge_end_north,
    ' <td colspan=2 class="##class## eb"></td>' . "\n" .
    ' <td class="##class## eb" style="border-bottom: ##border##; border-left: ##border##;">&nbsp;</td>' . "\n" .
    ' <td rowspan=3 class="##class## eb">&nbsp;</td>',
    ' <td colspan=3 rowspan=2 class="##class## eb"></td>',
    '',
   ],

  EDGE_N_E() + EDGE_START_N() => [
    $edge_empty_row,
    ' <td colspan=2 rowspan=3 class="##class## eb"></td>' . "\n" .
    ' <td colspan=2 class="##class## eb" style="border-bottom: ##border##; border-left: ##border##;">&nbsp;</td>',
    ' <td colspan=2 class="##class## eb"></td>',
    '',
   ],

  EDGE_N_E() + EDGE_END_N() => [
    $edge_end_north,
    ' <td colspan=2 rowspan=3 class="##class## eb"></td>' . "\n" .
    ' <td colspan=2 class="##class## eb" style="border-bottom: ##border##; border-left: ##border##;">&nbsp;</td>',
    '',
    ' <td colspan=2 class="##class## eb"></td>',
   ],

  ###########################################################################
  ###########################################################################
  # self loops

  EDGE_LOOP_NORTH() - EDGE_LABEL_CELL() => [
    '<td rowspan=2 class="##class## eb">&nbsp;</td>' . "\n".
    ' <td colspan=2 rowspan=2 class="##class## lh" style="border-bottom: ##border##;##lc####bg##">##label##</td>' . "\n" .
    ' <td rowspan=2 class="##class## eb">&nbsp;</td>',
    '',
    '<td class="##class## eb">&nbsp;</td>' . "\n".
    ' <td colspan=2 class="##class## eb" style="border-left: ##border##;##bg##">&nbsp;</td>'."\n".
    ' <td class="##class## eb" style="border-left: ##border##;##bg##">&nbsp;</td>',

    '<td colspan=2 class="##class## v" style="##bg##"##edgecolor##>v</td>' . "\n" .
    ' <td colspan=2 class="##class## eb">&nbsp;</td>',

   ],

  EDGE_LOOP_SOUTH() - EDGE_LABEL_CELL() => [
    '<td colspan=2 class="##class## v" style="##bg##"##edgecolor##>^</td>' . "\n" . 
    ' <td colspan=2 class="##class## eb">&nbsp;</td>',

    '<td rowspan=2 class="##class## eb">&nbsp;</td>' . "\n".
    ' <td colspan=2 rowspan=2 class="##class## lh" style="border-left:##border##;border-bottom:##border##;##lc####bg##">##label##</td>'."\n".
    ' <td rowspan=2 class="##class## eb" style="border-left:##border##;##bg##">&nbsp;</td>',

    '',

    '<td colspan=4 class="##class## eb">&nbsp;</td>',

   ],

  EDGE_LOOP_WEST() - EDGE_LABEL_CELL() => [
    $edge_empty_row.
    ' <td colspan=2 rowspan=2 class="##class## lh" style="border-bottom: ##border##;##lc####bg##">##label##</td>'."\n".
    ' <td rowspan=2 class="##class## eb">&nbsp;</td>',

    '',

    '<td colspan=2 class="##class## eb" style="border-left: ##border##; border-bottom: ##border##;##bg##">&nbsp;</td>' . "\n".
    ' <td rowspan=2 class="##class## va" style="##bg##"##edgecolor##><span class="sa">&gt;</span></td>',
    
    '<td colspan=2 class="##class## eb">&nbsp;</td>',
   ],

  EDGE_LOOP_EAST() - EDGE_LABEL_CELL() => [

    '<td rowspan=2 class="##class## eb">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## lh" style="border-bottom: ##border##;##lc####bg##">##label##</td>' ."\n".
    ' <td rowspan=2 class="##class## eb">&nbsp;</td>',

    '',

    '<td rowspan=2 class="##class## va" style="##bg##"##edgecolor##><span class="sh">&lt;</span></td>' ."\n".
    ' <td colspan=2 class="##class## eb" style="border-bottom: ##border##;##bg##">&nbsp;</td>'."\n".
    ' <td class="##class## eb" style="border-left: ##border##;##bg##">&nbsp;</td>',
   
    '<td colspan=3 class="##class## eb">&nbsp;</td>',
   ],

  ###########################################################################
  ###########################################################################
  # joints

  ###########################################################################
  # E_N_S

  EDGE_E_N_S() => [
    '<td colspan=2 rowspan=2 class="##class## eb">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left:##borderv##;border-bottom:##border##;##bg##">&nbsp;</td>',
    '',
    '<td colspan=2 rowspan=2 class="##class## eb">&nbsp;</td>' ."\n".
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##borderv##;##bg##">&nbsp;</td>',
    '',
   ],

  EDGE_E_N_S() + EDGE_END_E() => [
    '<td colspan=2 rowspan=2 class="##class## eb">&nbsp;</td>' . "\n" .
    ' <td rowspan=2 class="##class## eb" style="border-left: ##borderv##; border-bottom: ##border##;##bg##">&nbsp;</td>' . "\n" .
    ' <td rowspan=4 class="##class## va"##edgecolor##><span class="sa">&gt;</span></td>',
    '',
    '<td colspan=2 rowspan=2 class="##class## eb">&nbsp;</td>' ."\n".
    ' <td rowspan=2 class="##class## eb" style="border-left: ##borderv##;##bg##">&nbsp;</td>',
    '',
   ],

  ###########################################################################
  # W_N_S

  EDGE_W_N_S() => [
    '<td colspan=2 rowspan=2 class="##class## eb" style="border-bottom: ##border##;##bg##">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=4 class="##class## eb" style="border-left: ##borderv##;##bg##">&nbsp;</td>',
    '',
    '<td colspan=2 rowspan=2 class="##class## eb">&nbsp;</td>',
    '',
   ],

  ###########################################################################
  # S_E_W

  EDGE_S_E_W() => [
    '<td colspan=4 rowspan=2 class="##class## eb" style="border-bottom: ##border##;##bg##">&nbsp;</td>',
    '',
    '<td colspan=2 rowspan=2 class="##class## eb">&nbsp;</td>' ."\n".
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##borderv##;##bg##">&nbsp;</td>',
    '',
   ],

  EDGE_S_E_W() + EDGE_END_S() => [
    '<td colspan=4 rowspan=2 class="##class## eb" style="border-bottom: ##border##;##bg##">&nbsp;</td>',
    '',
    '<td colspan=2 class="##class## eb">&nbsp;</td>' ."\n".
    ' <td colspan=2 class="##class## eb" style="border-left: ##borderv##;##bg##">&nbsp;</td>',
    $edge_end_south,
   ],

  EDGE_S_E_W() + EDGE_START_S() => [
    '<td colspan=4 rowspan=2 class="##class## eb" style="border-bottom: ##border##;##bg##">&nbsp;</td>',
    '',
    '<td colspan=2 class="##class## eb">&nbsp;</td>' ."\n".
    ' <td colspan=2 class="##class## eb" style="border-left: ##borderv##;##bg##">&nbsp;</td>',
    ' <td colspan=4 class="##class## eb"></td>',
   ],

  EDGE_S_E_W() + EDGE_START_W() => [
    '<td rowspan=4 class="##class## el"></td>' . "\n" .
    '<td colspan=3 rowspan=2 class="##class## eb" style="border-bottom: ##border##;##bg##">&nbsp;</td>',
    '',
    '<td rowspan=2 class="##class## eb">&nbsp;</td>' ."\n".
    ' <td rowspan=2 class="##class## eb" style="border-left: ##borderv##;##bg##">&nbsp;</td>',
    '',

   ],

  EDGE_S_E_W() + EDGE_END_E() => [
    '<td colspan=3 rowspan=2 class="##class## eb" style="border-bottom: ##border##;##bg##">&nbsp;</td>' . "\n" .
    ' <td rowspan=4 class="##class## va"##edgecolor##><span class="sa">&gt;</span></td>',
    '',
    '<td colspan=2 rowspan=2 class="##class## eb">&nbsp;</td>' ."\n".
    ' <td rowspan=2 class="##class## eb" style="border-left: ##borderv##;##bg##">&nbsp;</td>',
    '',
   ],

  EDGE_S_E_W() + EDGE_END_W() => [
    $edge_arrow_west_upper .
    '<td colspan=3 rowspan=2 class="##class## eb" style="border-bottom: ##border##;##bg##">&nbsp;</td>' . "\n" ,
    '',
    '<td colspan=2 rowspan=2 class="##class## eb">&nbsp;</td>' ."\n" .
    '<td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##borderv##;##bg##">&nbsp;</td>',
   ],

  ###########################################################################
  # N_E_W

  EDGE_N_E_W() => [
    ' <td colspan=2 rowspan=2 class="##class## eb" style="border-bottom: ##borderv##;##bg##">&nbsp;</td>' ."\n".
    '<td colspan=2 rowspan=2 class="##class## eb" style="border-left: ##borderv##; border-bottom: ##border##;##bg##">&nbsp;</td>',
    '',
    '<td colspan=4 rowspan=2 class="##class## eb">&nbsp;</td>',
    '',
   ],

  EDGE_N_E_W() + EDGE_END_N() => [
    $edge_end_north,
    ' <td colspan=2 class="##class## eb" style="border-bottom: ##borderv##;##bg##">&nbsp;</td>' ."\n".
    '<td colspan=2 class="##class## eb" style="border-left: ##borderv##; border-bottom: ##border##;##bg##">&nbsp;</td>',
    '',
    '<td colspan=4 rowspan=2 class="##class## eb">&nbsp;</td>',
    '',
   ],

  EDGE_N_E_W() + EDGE_START_N() => [
    $edge_empty_row,
    ' <td colspan=2 class="##class## eb" style="border-bottom: ##borderv##;##bg##">&nbsp;</td>' ."\n".
    '<td colspan=2 class="##class## eb" style="border-left: ##borderv##; border-bottom: ##border##;##bg##">&nbsp;</td>',
    '',
    '<td colspan=4 rowspan=2 class="##class## eb">&nbsp;</td>',
    '',
   ],

  };

sub _html_edge_hor
  {
  # Return HTML code for a horizontal edge (with all start/end combinations)
  # as [], with code for each table row.
  my ($self, $as) = @_;

  my $s_flags = $self->{type} & EDGE_START_MASK;
  my $e_flags = $self->{type} & EDGE_END_MASK;

  $e_flags = 0 if $as eq 'none';

  # XXX TODO: we could skip the output of "eb" parts when this edge doesn't belong
  # to a group.

  my $rc = [
    ' <td colspan=##mod## rowspan=2 class="##class## lh" style="border-bottom: ##border##;##lc####bg##">##label##</td>',
    '',
    '<td colspan=##mod## rowspan=2 class="##class## eb">&nbsp;</td>', 
    '',
    ];

  # This assumes that only 2 end/start flags are set at the same time:

  my $mod = 4;							# modifier
  if ($s_flags & EDGE_START_W)
    {
    $mod--;
    $rc->[0] = '<td rowspan=4 class="##class## el"></td>' . "\n" . $rc->[0];
    };
  if ($s_flags & EDGE_START_E)
    {
    $mod--;
    $rc->[0] .= "\n " . '<td rowspan=4 class="##class## el"></td>';
    };
  if ($e_flags & EDGE_END_W)
    {
    $mod--;
    $rc->[0] = $edge_arrow_west_upper . $rc->[0]; 
    $rc->[2] = $edge_arrow_west_lower . $rc->[2]; 
    }
  if ($e_flags & EDGE_END_E)
    { 
    $mod--;
    $rc->[0] .= "\n " . $edge_arrow_east_upper;
    $rc->[2] .= "\n " . $edge_arrow_east_lower;
    };

  # cx == 1: mod = 2..4, cx == 2: mod = 6..8, etc.
  $self->{cx} ||= 1;
  $mod = $self->{cx} * 4 - 4 + $mod;

  for my $e (@$rc)
    {
    $e =~ s/##mod##/$mod/g;
    }

  $rc;
  }

sub _html_edge_ver
  {
  # Return HTML code for a vertical edge (with all start/end combinations)
  # as [], with code for each table row.
  my ($self, $as) = @_;

  my $s_flags = $self->{type} & EDGE_START_MASK;
  my $e_flags = $self->{type} & EDGE_END_MASK;

  $e_flags = 0 if $as eq 'none';

  my $mod = 4; 							# modifier

  # normal vertical edge with no start/end flags
  my $rc = [
    '<td colspan=2 rowspan=##mod## class="##class## el">&nbsp;</td>' . "\n " . 
    '<td colspan=2 rowspan=##mod## class="##class## lv" style="border-left: ##border##;##lc####bg##">##label##</td>' . "\n",
    '',
    '',
    '',
    ];

  # flag north
  if ($s_flags & EDGE_START_N)
    {
    $mod--;
    unshift @$rc, '<td colspan=4 class="##class## eb"></td>' . "\n";
    delete $rc->[-1];
    }
  elsif ($e_flags & EDGE_END_N)
    {
    $mod--;
    unshift @$rc, $edge_end_north;
    delete $rc->[-1];
    }

  # flag south
  if ($s_flags & EDGE_START_S)
    {
    $mod--;
    $rc->[3] = '<td colspan=4 class="##class## eb"></td>' . "\n"
    }

  if ($e_flags & EDGE_END_S)
    {
    $mod--;
    $rc->[3] = $edge_end_south;
    }

  $self->{cy} ||= 1;
  $mod = $self->{cy} * 4 - 4 + $mod;

  for my $e (@$rc)
    {
    $e =~ s/##mod##/$mod/g;
    }

  $rc;
  }

sub _html_edge_cross
  {
  # Return HTML code for a crossingedge (with all start/end combinations)
  # as [], with code for each table row.
  my ($self, $N, $S, $E, $W) = @_;

#  my $s_flags = $self->{type} & EDGE_START_MASK;
#  my $e_flags = $self->{type} & EDGE_END_MASK;

  my $rc = [
    ' <td colspan=2 rowspan=2 class="##class## eb el" style="border-bottom: ##border##">&nbsp;</td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb el" style="border-left: ##borderv##; border-bottom: ##border##">&nbsp;</td>' . "\n",
    '',
    ' <td colspan=2 rowspan=2 class="##class## eb el"></td>' . "\n" .
    ' <td colspan=2 rowspan=2 class="##class## eb el" style="border-left: ##borderv##">&nbsp;</td>' . "\n",
    '',
    ];

  $rc;
  }

sub as_html
  {
  my ($self) = shift;

  my $type = $self->{type} & EDGE_NO_M_MASK;
  my $style = $self->{style};

  # none, open, filled, closed
  my $as; $as = 'none' if $self->{edge}->{undirected};
  $as = $self->attribute('arrowstyle') unless $as;
  
  # triangle, box, dot, inv, diamond, line etc.
  my $ashape; $ashape = 'triangle' if $self->{edge}->{undirected};
  $ashape = $self->attribute('arrowshape') unless $ashape;

  my $code = $edge_html->{$type};

  if (!defined $code)
    {
    my $t = $self->{type} & EDGE_TYPE_MASK;

    if ($style ne 'invisible')
      {
      $code = $self->_html_edge_hor($as) if $t == EDGE_HOR;
      $code = $self->_html_edge_ver($as) if $t == EDGE_VER;
      $code = $self->_html_edge_cross($as) if $t == EDGE_CROSS;
      }
    else
      {
      $code = [ ' <td colspan=4 rowspan=4 class="##class##">&nbsp;</td>' ];
      }

    if (!defined $code)
      {
      $code = [ ' <td colspan=4 rowspan=4 class="##class##">???</td>' ];
      warn ("as_html: Unimplemented edge type $self->{type} ($type) at $self->{x},$self->{y} "
	. edge_type($self->{type}));
      }
    }

  my $id = $self->{graph}->{id};

  my $color = $self->get_color_attribute('color');
  my $label = '';
  my $label_style = '';

  # only include the label if we are the label cell
  if ($style ne 'invisible' && ($self->{type} & EDGE_LABEL_CELL))
    {
    my $switch_to_center;
    ($label,$switch_to_center) = $self->_label_as_html();

    # replace linebreaks by <br>, but remove extra spaces 
    $label =~ s/\s*\\n\s*/<br \/>/g;

    my $label_color = $self->raw_color_attribute('labelcolor') || $color;
    $label_color = '' if $label_color eq '#000000';
    $label_style = "color: $label_color;" if $label_color;

    my $font = $self->attribute('font') || '';
    $font = '' if $font eq ($self->default_attribute('font') || '');
    $label_style = "font-family: $font;" if $font;
  
    $label_style .= $self->text_styles_as_css(1,1) unless $label eq '';

    $label_style =~ s/^\s*//;

    my $link = $self->link();
    if ($link ne '')
      {
      # encode critical entities
      $link =~ s/\s/\+/g;			# space
      $link =~ s/'/%27/g;			# single-quote

      # put the style on the link
      $label_style = " style='$label_style'" if $label_style;
      $label = "<a href='$link'$label_style>$label</a>";
      $label_style = '';
      }

    }
  # without &nbsp;, IE doesn't draw the cell-border nec. for edges
  $label = '&nbsp;' unless $label ne '';

  ###########################################################################
  # get the border styles/colors:

  # width for the edge is "2px"
  my $bow = '2';
  my $border = Graph::Easy::_border_attribute_as_html( $self->{style}, $bow, $color);
  my $border_v = $border;

  if (($self->{type} & EDGE_TYPE_MASK) == EDGE_CROSS)
   {
   $border_v = Graph::Easy::_border_attribute_as_html( $self->{style_ver}, $bow, $self->{color_ver});
   }

  ###########################################################################
  my $edge_color = ''; $edge_color = " color: $color;" if $color;

  # If the group doesn't have a fill attribute, then it is defined in the CSS
  # of the group, and since we get the same class, we can skip the background.
  # But if the group has a fill, we need to use this as override.
  # The idea behind is to omit the "background: #daffff;" as much as possible.

  my $bg = $self->attribute('background') || '';
  my $group = $self->{edge}->{group};
  $bg = '' if $bg eq 'inherit';
  $bg = $group->{att}->{fill} if $group->{att}->{fill} && $bg eq '';
  $bg = '' if $bg eq 'inherit';
  $bg = " background: $bg;" if $bg;

  my $title = $self->title();
  $title =~ s/"/&#22;/g;			# replace quotation marks
  $title = " title=\"$title\"" if $title ne '';	# add mouse-over title

  ###########################################################################
  # replace templates
      
  require Graph::Easy::As_ascii if $as ne 'none';	# for _unicode_arrow()

  # replace borderv with the border for the vertical edge on CROSS sections
  $border =~ s/\s+/ /g;			# collapse multiple spaces
  $border_v =~ s/\s+/ /g;
  my $cl = $self->class(); $cl =~ s/\./_/g;	# group.cities => group_cities

  my $rc;
  for my $a (@$code)
    {
    if (ref($a))
      {
      for my $c (@$a)
        {
        push @$rc, $self->_format_td($c, 
	  $border, $border_v, $label_style, $edge_color, $bg, $as, $ashape, $title, $label, $cl);
	}
      }
    else
      {
      push @$rc, $self->_format_td($a, 
	$border, $border_v, $label_style, $edge_color, $bg, $as, $ashape, $title, $label, $cl);
      }
    }

  $rc;
  }

sub _format_td
  {
  my ($self, $c,
	$border, $border_v, $label_style, $edge_color, $bg, $as, $ashape, $title, $label, $cl) = @_;

  # insert 'style="##bg##"' unless there is already a style 
  $c =~ s/( e[bl]")(>(&nbsp;)?<\/td>)/$1 style="##bg##"$2/g;
  # insert missing "##bg##"
  $c =~ s/style="border/style="##bg##border/g;

  $c =~ s/##class##/$cl/g;
  $c =~ s/##border##/$border/g;
  $c =~ s/##borderv##/$border_v/g;
  $c =~ s/##lc##/$label_style/g;
  $c =~ s/##edgecolor##/ style="$edge_color"/g;
  $c =~ s/##ec##/$edge_color/g;
  $c =~ s/##bg##/$bg/g;
  $c =~ s/ style=""//g;		# remove empty styles

  # remove arrows if edge is undirected
  $c =~ s/>(v|\^|&lt;|&gt;)/>/g if $as eq 'none';

  # insert "nice" looking Unicode arrows
  $c =~ s/>(v|\^|&lt;|&gt;)/'>' . $self->_unicode_arrow($ashape, $as, $1); /eg;

  # insert the label last, other "v" as label might get replaced above
  $c =~ s/>##label##/$title>$label/;
  # for empty labels use a different class
  $c =~ s/ lh"/ eb"/ if $label eq '';

  $c .= "\n" unless $c =~ /\n\z/;

  $self->quoted_comment() . $c;
  }

sub class
  {
  my $self = shift;

  my $c = $self->{class} . ($self->{cell_class} || '');
  $c = $self->{edge}->{group}->class() . ' ' . $c if ref($self->{edge}->{group});

  $c;
  }

sub group
  {
  # return the group we belong to as the group of our parent-edge
  my $self = shift;

  $self->{edge}->{group};
  }

#############################################################################
# accessor methods

sub type
  {
  # get/set type of this path element
  # type - EDGE_START, EDGE_END, EDGE_HOR, EDGE_VER, etc
  my ($self,$type) = @_;

  if (defined $type)
    {
    if (defined $type && $type < 0 || $type > EDGE_MAX_TYPE)
      {
      require Carp;
      Carp::confess ("Cell type $type for cell $self->{x},$self->{y} is not valid.");
      }
    $self->{type} = $type;
    }

  $self->{type};
  }

#############################################################################

# For rendering this path element as ASCII, we need to correct our width based
# on whether we have a border or not. But this is only known after parsing is
# complete.

sub _correct_size
  {
  my ($self,$format) = @_;

  return if defined $self->{w};

  # min-size is this 
  $self->{w} = 5; $self->{h} = 3;
  # make short cell pieces very small
  if (($self->{type} & EDGE_SHORT_CELL) != 0)
    {
    $self->{w} = 1; $self->{h} = 1;
    return;
    }
    
  my $arrows = ($self->{type} & EDGE_ARROW_MASK);
  my $type = ($self->{type} & EDGE_TYPE_MASK);

  if ($self->{edge}->{bidirectional} && $arrows != 0)
    {
    $self->{w}++ if $type == EDGE_HOR;
    $self->{h}++ if $type == EDGE_VER;
    }

  # make joints bigger if they got arrows
  my $ah = $self->{type} & EDGE_ARROW_HOR;
  my $av = $self->{type} & EDGE_ARROW_VER;
  $self->{w}++ if $ah && ($type == EDGE_S_E_W || $type == EDGE_N_E_W);
  $self->{h}++ if $av && ($type == EDGE_E_N_S || $type == EDGE_W_N_S);

  my $style = $self->{edge}->attribute('style') || 'solid';

  # make the edge to display ' ..-> ' instead of ' ..> ':
  $self->{w}++ if $style eq 'dot-dot-dash';

  if ($type >= EDGE_LOOP_TYPE)
    {
    #  +---+ 
    #  |   V

    #       +
    #  +--> |
    #  |    |
    #  +--- |
    #       +
    $self->{w} = 7;
    $self->{w} = 8 if $type == EDGE_N_W_S || $type == EDGE_S_W_N;
    $self->{h} = 3;
    $self->{h} = 5 if $type != EDGE_N_W_S && $type != EDGE_S_W_N;
    }

  if ($self->{type} == EDGE_HOR)
    {
    $self->{w} = 0;
    }
  elsif ($self->{type} == EDGE_VER)
    {
    $self->{h} = 0;
    }
  elsif ($self->{type} & EDGE_LABEL_CELL)
    {
    # edges do not have borders
    my ($w,$h) = $self->dimensions(); $h-- unless $h == 0;

    $h += $self->{h};
    $w += $self->{w};
    $self->{w} = $w;
    $self->{h} = $h;
    }
  }

#############################################################################
# attribute handling

sub attribute
  {
  my ($self, $name) = @_;

  my $edge = $self->{edge};

#  my $native = $edge->{att}->{$name};
#  return $native if defined $native && $native ne 'inherit';

  # shortcut, look up the attribute directly
  return $edge->{att}->{$name}
    if defined $edge->{att}->{$name} && $edge->{att}->{$name} ne 'inherit';

  return $edge->attribute($name);

  # XXX TODO This does not work, since caching the attribute doesn't get invalidated
  # upon set_attribute().

#  $edge->{cache} = {} unless exists $edge->{cache};
#  $edge->{cache}->{att} = {} unless exists $edge->{cache}->{att};
#
#  my $cache = $edge->{cache}->{att};
#  return $cache->{$name} if exists $cache->{$name};
#
#  my $rc = $edge->attribute($name);
#  # only cache values that weren't inherited to avoid cache problems
#  $cache->{$name} = $rc unless defined $native && $native eq 'inherit';
#
#  $rc;
  }

1;

#############################################################################
#############################################################################

package Graph::Easy::Edge::Cell::Empty;

require Graph::Easy::Node::Cell;
our @ISA = qw/Graph::Easy::Node::Cell/;

#use vars qw/$VERSION/;

our $VERSION = '0.02';

use constant isa_cell => 1;

1;
__END__

=head1 NAME

Graph::Easy::Edge::Cell - A cell in an edge in Graph::Easy

=head1 SYNOPSIS

        use Graph::Easy;

	my $ssl = Graph::Easy::Edge->new(
		label => 'encrypted connection',
		style => 'solid',
		color => 'red',
	);
	my $src = Graph::Easy::Node->new( 'source' );
	my $dst = Graph::Easy::Node->new( 'destination' );

	$graph = Graph::Easy->new();

	$graph->add_edge($src, $dst, $ssl);

	print $graph->as_ascii();

=head1 DESCRIPTION

A C<Graph::Easy::Edge::Cell> represents an edge between two (or more) nodes
in a simple graph.

Each edge has a direction (from source to destination, or back and forth),
plus a style (line width and style), colors etc. It can also have a name,
e.g. a text label associated with it.

There should be no need to use this package directly.

=head1 METHODS

=head2 error()

	$last_error = $edge->error();

	$cvt->error($error);			# set new messags
	$cvt->error('');			# clear error

Returns the last error message, or '' for no error.

=head2 as_ascii()

	my $ascii = $path->as_ascii();

Returns the path-cell as a little ascii representation.

=head2 as_html()

	my $html = $path->as_html($tag,$id);

eturns the path-cell as HTML code.

=head2 label()

	my $label = $path->label();

Returns the name (also known as 'label') of the path-cell.

=head2 style()

	my $style = $edge->style();

Returns the style of the edge.

=head1 EXPORT

None by default. Can export the following on request:

  EDGE_START_E
  EDGE_START_W
  EDGE_START_N
  EDGE_START_S

  EDGE_END_E
  EDGE_END_W	
  EDGE_END_N
  EDGE_END_S

  EDGE_SHORT_E
  EDGE_SHORT_W	
  EDGE_SHORT_N
  EDGE_SHORT_S

  EDGE_SHORT_BD_EW
  EDGE_SHORT_BD_NS

  EDGE_SHORT_UN_EW
  EDGE_SHORT_UN_NS

  EDGE_HOR
  EDGE_VER
  EDGE_CROSS

  EDGE_N_E
  EDGE_N_W
  EDGE_S_E
  EDGE_S_W

  EDGE_S_E_W
  EDGE_N_E_W
  EDGE_E_N_S
  EDGE_W_N_S	

  EDGE_LOOP_NORTH
  EDGE_LOOP_SOUTH
  EDGE_LOOP_EAST
  EDGE_LOOP_WEST

  EDGE_N_W_S
  EDGE_S_W_N
  EDGE_E_S_W
  EDGE_W_S_E

  EDGE_TYPE_MASK
  EDGE_FLAG_MASK
  EDGE_ARROW_MASK
  
  EDGE_START_MASK
  EDGE_END_MASK
  EDGE_MISC_MASK

  ARROW_RIGHT
  ARROW_LEFT
  ARROW_UP
  ARROW_DOWN

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2007 by Tels L<http://bloodgate.com>.

See the LICENSE file for more details.

=cut
#############################################################################
# A group of nodes. Part of Graph::Easy.
#
#############################################################################

package Graph::Easy::Group;

use Graph::Easy::Group::Cell;
use Graph::Easy;
use Scalar::Util qw/weaken/;

@ISA = qw/Graph::Easy::Node Graph::Easy/;
$VERSION = '0.22';

use strict;

#############################################################################

sub _init
  {
  # generic init, override in subclasses
  my ($self,$args) = @_;
  
  $self->{name} = 'Group #'. $self->{id};
  $self->{class} = 'group';
  $self->{_cells} = {};				# the Group::Cell objects
#  $self->{cx} = 1;
#  $self->{cy} = 1;

  foreach my $k (keys %$args)
    {
    if ($k !~ /^(graph|name)\z/)
      {
      require Carp;
      Carp::confess ("Invalid argument '$k' passed to Graph::Easy::Group->new()");
      }
    $self->{$k} = $args->{$k};
    }
  
  $self->{nodes} = {};
  $self->{groups} = {};
  $self->{att} = {};

  $self;
  }

#############################################################################
# accessor methods

sub nodes
  {
  my $self = shift;

  wantarray ? ( values %{$self->{nodes}} ) : scalar keys %{$self->{nodes}};
  }

sub edges
  {
  # edges leading from/to this group
  my $self = shift;

  wantarray ? ( values %{$self->{edges}} ) : scalar keys %{$self->{edges}};
  }

sub edges_within
  {
  # edges between nodes inside this group
  my $self = shift;

  wantarray ? ( values %{$self->{edges_within}} ) : 
		scalar keys %{$self->{edges_within}};
  }

sub _groups_within
  {
  my ($self, $level, $max_level, $cur) = @_;

  no warnings 'recursion';

  push @$cur, values %{$self->{groups}};

  return if $level >= $max_level;

  for my $g (values %{$self->{groups}})
    {
    $g->_groups_within($level+1,$max_level, $cur) if scalar keys %{$g->{groups}} > 0;
    }
  }

#############################################################################

sub set_attribute
  {
  my ($self, $name, $val, $class) = @_;

  $self->SUPER::set_attribute($name, $val, $class);

  # if defined attribute "nodeclass", put our nodes into that class
  if ($name eq 'nodeclass')
    {
    my $class = $self->{att}->{nodeclass};
    for my $node (values %{ $self->{nodes} } )
      {
      $node->sub_class($class);
      }
    }
  $self;
  }

sub shape
  {
  my ($self) = @_;

  # $self->{att}->{shape} || $self->attribute('shape');
  '';
  }

#############################################################################
# node handling

sub add_node
  {
  # add a node to this group
  my ($self,$n) = @_;

  if (!ref($n) || !$n->isa("Graph::Easy::Node"))
    {
    if (!ref($self->{graph}))
      {
      return $self->error("Cannot add non node-object $n to group '$self->{name}'");
      }
    $n = $self->{graph}->add_node($n);
    }
  $self->{nodes}->{ $n->{name} } = $n;

  # if defined attribute "nodeclass", put our nodes into that class
  $n->sub_class($self->{att}->{nodeclass}) if exists $self->{att}->{nodeclass};

  # register ourselves with the member
  $n->{group} = $self;

  # set the proper attribute (for layout)
  $n->{att}->{group} = $self->{name};

  # Register the nodes and the edge with our graph object
  # and weaken the references. Be carefull to not needlessly
  # override and weaken again an already existing reference, this
  # is an O(N) operation in most Perl versions, and thus very slow.

  # If the node does not belong to a graph yet or belongs to another
  # graph, add it to our own graph:
  weaken($n->{graph} = $self->{graph}) unless
	$n->{graph} && $self->{graph} && $n->{graph} == $self->{graph};

  $n;
  }

sub add_member
  {
  # add a node or group to this group
  my ($self,$n) = @_;
 
  if (!ref($n) || !$n->isa("Graph::Easy::Node"))
    {
    if (!ref($self->{graph}))
      {
      return $self->error("Cannot add non node-object $n to group '$self->{name}'");
      }
    $n = $self->{graph}->add_node($n);
    }
  return $self->_add_edge($n) if $n->isa("Graph::Easy::Edge");
  return $self->add_group($n) if $n->isa('Graph::Easy::Group');

  $self->{nodes}->{ $n->{name} } = $n;

  # if defined attribute "nodeclass", put our nodes into that class
  my $cl = $self->attribute('nodeclass');
  $n->sub_class($cl) if $cl ne '';

  # register ourselves with the member
  $n->{group} = $self;

  # set the proper attribute (for layout)
  $n->{att}->{group} = $self->{name};

  # Register the nodes and the edge with our graph object
  # and weaken the references. Be carefull to not needlessly
  # override and weaken again an already existing reference, this
  # is an O(N) operation in most Perl versions, and thus very slow.

  # If the node does not belong to a graph yet or belongs to another
  # graph, add it to our own graph:
  weaken($n->{graph} = $self->{graph}) unless
	$n->{graph} && $self->{graph} && $n->{graph} == $self->{graph};

  $n;
  }

sub del_member
  {
  # delete a node or group from this group
  my ($self,$n) = @_;

  # XXX TOOD: groups vs. nodes
  my $class = 'nodes'; my $key = 'name';
  if ($n->isa('Graph::Easy::Group'))
    {
    # XXX TOOD: groups vs. nodes
    $class = 'groups'; $key = 'id';
    }
  delete $self->{$class}->{ $n->{$key} };
  delete $n->{group};			# unregister us

  if ($n->isa('Graph::Easy::Node'))
    {
    # find all edges that mention this node and drop them from the group
    my $edges = $self->{edges_within};
    for my $e (values %$edges)
      {
      delete $edges->{ $e->{id} } if $e->{from} == $n || $e->{to} == $n;
      }
    }

  $self;
  }

sub del_node
  {
  # delete a node from this group
  my ($self,$n) = @_;

  delete $self->{nodes}->{ $n->{name} };
  delete $n->{group};			# unregister us
  delete $n->{att}->{group};		# delete the group attribute

  # find all edges that mention this node and drop them from the group
  my $edges = $self->{edges_within};
  for my $e (values %$edges)
    {
    delete $edges->{ $e->{id} } if $e->{from} == $n || $e->{to} == $n;
    }

  $self;
  }

sub add_nodes
  {
  my $self = shift;

  # make a copy in case of scalars
  my @arg = @_;
  foreach my $n (@arg)
    {
    if (!ref($n) && !ref($self->{graph}))
      {
      return $self->error("Cannot add non node-object $n to group '$self->{name}'");
      }
    return $self->error("Cannot add group-object $n to group '$self->{name}'")
      if $n->isa('Graph::Easy::Group');

    $n = $self->{graph}->add_node($n) unless ref($n);

    $self->{nodes}->{ $n->{name} } = $n;

    # set the proper attribute (for layout)
    $n->{att}->{group} = $self->{name};

#   XXX TODO TEST!
#    # if defined attribute "nodeclass", put our nodes into that class
#    $n->sub_class($self->{att}->{nodeclass}) if exists $self->{att}->{nodeclass};

    # register ourselves with the member
    $n->{group} = $self;

    # Register the nodes and the edge with our graph object
    # and weaken the references. Be carefull to not needlessly
    # override and weaken again an already existing reference, this
    # is an O(N) operation in most Perl versions, and thus very slow.

    # If the node does not belong to a graph yet or belongs to another
    # graph, add it to our own graph:
    weaken($n->{graph} = $self->{graph}) unless
	$n->{graph} && $self->{graph} && $n->{graph} == $self->{graph};

    }

  @arg;
  }

#############################################################################

sub _del_edge
  {
  # delete an edge from this group
  my ($self,$e) = @_;

  delete $self->{edges_within}->{ $e->{id} };
  delete $e->{group};			# unregister us

  $self;
  }

sub _add_edge
  {
  # add an edge to this group (e.g. when both from/to of this edge belong
  # to this group)
  my ($self,$e) = @_;

  if (!ref($e) || !$e->isa("Graph::Easy::Edge"))
    {
    return $self->error("Cannot add non edge-object $e to group '$self->{name}'");
    }
  $self->{edges_within}->{ $e->{id} } = $e;

  # if defined attribute "edgeclass", put our edges into that class
  my $edge_class = $self->attribute('edgeclass');
  $e->sub_class($edge_class) if $edge_class ne '';

  # XXX TODO: inline
  $self->add_node($e->{from});
  $self->add_node($e->{to});

  # register us, but don't do weaken() if the ref was already set
  weaken($e->{group} = $self) unless defined $e->{group} && $e->{group} == $self;

  $e;
  }

sub add_edge
  {
  # Add an edge to the graph of this group, then register it with this group.
  my ($self,$from,$to) = @_;

  my $g = $self->{graph};
  return $self->error("Cannot add edge to group '$self->{name}' without graph")
    unless defined $g;

  my $edge = $g->add_edge($from,$to);

  $self->_add_edge($edge);
  }

sub add_edge_once
  {
  # Add an edge to the graph of this group, then register it with this group.
  my ($self,$from,$to) = @_;

  my $g = $self->{graph};
  return $self->error("Cannot non edge to group '$self->{name}' without graph")
    unless defined $g;

  my $edge = $g->add_edge_once($from,$to);
  # edge already exists => so fetch it
  $edge = $g->edge($from,$to) unless defined $edge;

  $self->_add_edge($edge);
  }

#############################################################################

sub add_group
  {
  # add a group to us
  my ($self,$group) = @_;

  # group with that name already exists?
  my $name = $group;
  $group = $self->{groups}->{ $group } unless ref $group;

  # group with that name doesn't exist, so create new one
  $group = $self->{graph}->add_group($name) unless ref $group;

  # index under the group name for easier lookup
  $self->{groups}->{ $group->{name} } = $group;

  # make attribute->('group') work
  $group->{att}->{group} = $self->{name};

  # register group with the graph and ourself
  $group->{graph} = $self->{graph};
  $group->{group} = $self;
  {
    no warnings; # dont warn on already weak references
    weaken($group->{graph});
    weaken($group->{group});
  }
  $self->{graph}->{score} = undef;		# invalidate last layout

  $group;
  }

# cell management - used by the layouter

sub _cells
  {
  # return all the cells this group currently occupies
  my $self = shift;

  $self->{_cells};
  }

sub _clear_cells
  {
  # remove all belonging cells
  my $self = shift;

  $self->{_cells} = {};

  $self;
  }

sub _add_cell
  {
  # add a cell to the list of cells this group covers
  my ($self,$cell) = @_;

  $cell->_update_boundaries();
  $self->{_cells}->{"$cell->{x},$cell->{y}"} = $cell;
  $cell;
  }

sub _del_cell
  {
  # delete a cell from the list of cells this group covers
  my ($self,$cell) = @_;

  delete $self->{_cells}->{"$cell->{x},$cell->{y}"};
  delete $cell->{group};

  $self;
  }

sub _find_label_cell
  {
  # go through all cells of this group and find one where to attach the label
  my $self = shift;

  my $g = $self->{graph};

  my $align = $self->attribute('align');
  my $loc = $self->attribute('labelpos');

  # depending on whether the label should be on top or bottom:
  my $match = qr/^\s*gt\s*\z/;
  $match = qr/^\s*gb\s*\z/ if $loc eq 'bottom';

  my $lc;						# the label cell

  for my $c (values %{$self->{_cells}})
    {
    # find a cell where to put the label
    next unless $c->{cell_class} =~ $match;

    if (defined $lc)
      {
      if ($align eq 'left')
	{
	# find top-most, left-most cell
	next if $lc->{x} < $c->{x} || $lc->{y} < $c->{y};
	}
      elsif ($align eq 'center')
	{
	# just find any top-most cell
	next if $lc->{y} < $c->{y};
	}
      elsif ($align eq 'right')
	{
	# find top-most, right-most cell
	next if $lc->{x} > $c->{x} || $lc->{y} < $c->{y};
	}
      }  
    $lc = $c;
    }

  # find the cell mostly near the center in the found top-row
  if (ref($lc) && $align eq 'center')
    {
    my ($left, $right);
    # find left/right most coordinates
    for my $c (values %{$self->{_cells}})
      {
      next if $c->{y} != $lc->{y};
      $left = $c->{x} if !defined $left || $left > $c->{x};  
      $right = $c->{x} if !defined $right || $right < $c->{x};
      }
    my $center = int(($right - $left) / 2 + $left);
    my $min_dist;
    # find the cell mostly near the center in the found top-row
    for my $c (values %{$self->{_cells}})
      {
      next if $c->{y} != $lc->{y};
      # squared to get rid of sign
      my $dist = ($center - $c->{x}); $dist *= $dist;
      next if defined $min_dist && $dist > $min_dist;
      $min_dist = $dist; $lc = $c;
      }
    }

  print STDERR "# Setting label for group '$self->{name}' at $lc->{x},$lc->{y}\n"
	if $self->{debug};

  $lc->_set_label() if ref($lc);
  }

sub layout
  {
  my $self = shift;

  $self->_croak('Cannot call layout() on a Graph::Easy::Group directly.');
  }

sub _layout
  {
  my $self = shift;

  ###########################################################################
  # set local {debug} for groups
  local $self->{debug} = $self->{graph}->{debug};

  $self->SUPER::_layout();
  }

sub _set_cell_types
  {
  my ($self, $cells) = @_;

  # Set the right cell class for all of our cells:
  for my $cell (values %{$self->{_cells}})
    {
    $cell->_set_type($cells);
    }
 
  $self;
  }

1;
__END__

=head1 NAME

Graph::Easy::Group - A group of nodes (aka subgraph) in Graph::Easy

=head1 SYNOPSIS

        use Graph::Easy;

        my $bonn = Graph::Easy::Node->new('Bonn');

        $bonn->set_attribute('border', 'solid 1px black');

        my $berlin = Graph::Easy::Node->new( name => 'Berlin' );

	my $cities = Graph::Easy::Group->new(
		name => 'Cities',
	);
        $cities->set_attribute('border', 'dashed 1px blue');

	$cities->add_nodes ($bonn);
	# $bonn will be ONCE in the group
	$cities->add_nodes ($bonn, $berlin);


=head1 DESCRIPTION

A C<Graph::Easy::Group> represents a group of nodes in an C<Graph::Easy>
object. These nodes are grouped together on output.

=head1 METHODS

=head2 new()

	my $group = Graph::Easy::Group->new( $options );

Create a new, empty group. C<$options> are the possible options, see
L<Graph::Easy::Node> for a list.

=head2 error()

	$last_error = $group->error();

	$group->error($error);			# set new messags
	$group->error('');			# clear error

Returns the last error message, or '' for no error.

=head2 as_ascii()

	my $ascii = $group->as_ascii();

Return the group as a little box drawn in ASCII art as a string.

=head2 name()

	my $name = $group->name();

Return the name of the group.

=head2 id()

	my $id = $group->id();

Returns the group's unique ID number.

=head2 set_attribute()

        $group->set_attribute('border-style', 'none');

Sets the specified attribute of this (and only this!) group to the
specified value.

=head2 add_member()

	$group->add_member($node);
	$group->add_member($group);

Add the specified object to this group and returns this member. If the
passed argument is a scalar, will treat it as a node name.

Note that each object can only be a member of one group at a time.

=head2 add_node()

	$group->add_node($node);

Add the specified node to this group and returns this node.

Note that each object can only be a member of one group at a time.

=head2 add_edge(), add_edge_once()

	$group->add_edge($edge);		# Graph::Easy::Edge
	$group->add_edge($from, $to);		# Graph::Easy::Node or
						# Graph::Easy::Group
	$group->add_edge('From', 'To');		# Scalars

If passed an Graph::Easy::Edge object, moves the nodes involved in
this edge to the group.

if passed two nodes, adds these nodes to the graph (unless they already
exist) and adds an edge between these two nodes. See L<add_edge_once()>
to avoid creating multiple edges.

This method works only on groups that are part of a graph.

Note that each object can only be a member of one group at a time,
and edges are automatically a member of a group if and only if both
the target and the destination node are a member of the same group.

=head2 add_group()

	my $inner = $group->add_group('Group name');
	my $nested = $group->add_group($group);

Add a group as subgroup to this group and returns this group.

=head2 del_member()

	$group->del_member($node);
	$group->del_member($group);

Delete the specified object from this group.

=head2 del_node()

	$group->del_node($node);

Delete the specified node from this group.

=head2 del_edge()

	$group->del_edge($edge);

Delete the specified edge from this group.

=head2 add_nodes()

	$group->add_nodes($node, $node2, ... );

Add all the specified nodes to this group and returns them as a list.

=head2 nodes()

	my @nodes = $group->nodes();

Returns a list of all node objects that belong to this group.

=head2 edges()

	my @edges = $group->edges();

Returns a list of all edge objects that lead to or from this group.

Note: This does B<not> return edges between nodes that are inside the group,
for this see L<edges_within()>.

=head2 edges_within()

	my @edges_within = $group->edges_within();

Returns a list of all edge objects that are I<inside> this group, in arbitrary
order. Edges are automatically considered I<inside> a group if their starting
and ending node both are in the same group.

Note: This does B<not> return edges between this group and other groups,
nor edges between this group and nodes outside this group, for this see
L<edges()>.

=head2 groups()

	my @groups = $group->groups();

Returns the contained groups of this group as L<Graph::Easy::Group> objects,
in arbitrary order.
  
=head2 groups_within()

	# equivalent to $group->groups():
	my @groups = $group->groups_within();		# all
	my @toplevel_groups = $group->groups_within(0);	# level 0 only

Return the groups that are inside this group, up to the specified level,
in arbitrary order.

The default level is -1, indicating no bounds and thus all contained
groups are returned.

A level of 0 means only the direct children, and hence only the toplevel
groups will be returned. A level 1 means the toplevel groups and their
toplevel children, and so on.

=head2 as_txt()

	my $txt = $group->as_txt();

Returns the group as Graph::Easy textual description.

=head2 _find_label_cell()

	$group->_find_label_cell();

Called by the layouter once for each group. Goes through all cells of this
group and finds one where to attach the label to. Internal usage only.

=head2 get_attributes()

        my $att = $object->get_attributes();

Return all effective attributes on this object (graph/node/group/edge) as
an anonymous hash ref. This respects inheritance and default values.

See also L<raw_attributes()>.

=head2 raw_attributes()

        my $att = $object->get_attributes();

Return all set attributes on this object (graph/node/group/edge) as
an anonymous hash ref. This respects inheritance, but does not include
default values for unset attributes.

See also L<get_attributes()>.

=head2 attribute related methods

You can call all the various attribute related methods like C<set_attribute()>,
C<get_attribute()>, etc. on a group, too. For example:

	$group->set_attribute('label', 'by train');
	my $attr = $group->get_attributes();

You can find more documentation in L<Graph::Easy>.

=head2 layout()

This routine should not be called on groups, it only works on the graph
itself.

=head2 shape()

	my $shape = $group->shape();

Returns the shape of the group as string.

=head2 has_as_successor()

	if ($group->has_as_successor($other))
	  {
	  ...
	  }

Returns true if C<$other> (a node or group) is a successor of this group, e.g.
if there is an edge leading from this group to C<$other>.

=head2 has_as_predecessor()

	if ($group->has_as_predecessor($other))
	  {
	  ...
	  }

Returns true if the group has C<$other> (a group or node) as predecessor, that
is if there is an edge leading from C<$other> to this group.

=head2 root_node()

	my $root = $group->root_node();

Return the root node as L<Graph::Easy::Node> object, if it was
set with the 'root' attribute.

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Graph::Easy>, L<Graph::Easy::Node>, L<Graph::Easy::Manual>.

=head1 AUTHOR

Copyright (C) 2004 - 2008 by Tels L<http://bloodgate.com>

See the LICENSE file for more details.

=cut
#############################################################################
# (c) by Tels 2004. Part of Graph::Easy. An anonymous group.
#
#############################################################################

package Graph::Easy::Group::Anon;

use Graph::Easy::Group;

@ISA = qw/Graph::Easy::Group/;
$VERSION = '0.02';

use strict;

sub _init
  {
  my $self = shift;

  $self->SUPER::_init(@_);

  $self->{name} = 'Group #' . $self->{id};
  $self->{class} = 'group.anon';

  $self->{att}->{label} = '';

  $self;
  }

sub _correct_size
  {
  my $self = shift;

  $self->{w} = 3;
  $self->{h} = 3;

  $self;
  }

sub attributes_as_txt
  {
  my $self = shift;

  $self->SUPER::attributes_as_txt( {
     node => {
       label => undef,
       shape => undef,
       class => undef,
       } } );
  }

sub as_pure_txt
  {
  '( )';
  }

sub _as_part_txt
  {
  '( )';
  }

sub as_graphviz_txt
  {
  my $self = shift;
  
  my $name = $self->{name};

  # quote special chars in name
  $name =~ s/([\[\]\(\)\{\}\#])/\\$1/g;

  '"' .  $name . '"';
  }

sub text_styles_as_css
  {
  '';
  }

sub is_anon
  {
  # is an anon group
  1;
  }

1;
__END__

=head1 NAME

Graph::Easy::Group::Anon - An anonymous group of nodes in Graph::Easy

=head1 SYNOPSIS

	use Graph::Easy::Group::Anon;

	my $anon = Graph::Easy::Group::Anon->new();

=head1 DESCRIPTION

A C<Graph::Easy::Group::Anon> represents an anonymous group of nodes,
e.g. a group without a name.

The syntax in the Graph::Easy textual description language looks like this:

	( [ Bonn ] -> [ Berlin ] )

This module is loaded and used automatically by Graph::Easy, so there is
no need to use it manually.

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Graph::Easy::Group>.

=head1 AUTHOR

Copyright (C) 2004 - 2006 by Tels L<http://bloodgate.com>.

See the LICENSE file for more details.

=cut
#############################################################################
# A cell of a group during layout. Part of Graph::Easy.
#
#############################################################################

package Graph::Easy::Group::Cell;

use Graph::Easy::Node;

@ISA = qw/Graph::Easy::Node/;
$VERSION = '0.14';

use strict;

BEGIN
  {
  *get_attribute = \&attribute;
  }

#############################################################################

# The different types for a group-cell:
use constant {
  GROUP_INNER		=> 0,	# completely sourounded by group cells
  GROUP_RIGHT		=> 1,	# right border only
  GROUP_LEFT		=> 2, 	# left border only
  GROUP_TOP	 	=> 3,	# top border only
  GROUP_BOTTOM 		=> 4, 	# bottom border only
  GROUP_ALL	 	=> 5,	# completely sourounded by non-group cells

  GROUP_BOTTOM_RIGHT	=> 6,	# bottom and right border
  GROUP_BOTTOM_LEFT	=> 7,	# bottom and left border
  GROUP_TOP_RIGHT	=> 8, 	# top and right border
  GROUP_TOP_LEFT	=> 9,	# top and left order

  GROUP_MAX		=> 5, 	# max number
  };

my $border_styles = 
  {
  # type		    top,	bottom, left,   right,	class
  GROUP_INNER()		=> [ 0,		0,	0,	0,	['gi'] ],
  GROUP_RIGHT()		=> [ 0,		0,	0,	1,	['gr'] ],
  GROUP_LEFT()		=> [ 0,		0,	1,	0,	['gl'] ],
  GROUP_TOP()		=> [ 1,		0,	0,	0,	['gt'] ],
  GROUP_BOTTOM()	=> [ 0,		1,	0,	0,	['gb'] ],
  GROUP_ALL()		=> [ 0,		0,	0,	0,	['ga'] ],
  GROUP_BOTTOM_RIGHT()	=> [ 0,		1,	0,	1,	['gb','gr'] ],
  GROUP_BOTTOM_LEFT()	=> [ 0,		1,	1,	0,	['gb','gl'] ],
  GROUP_TOP_RIGHT()	=> [ 1,		0,	0,	1,	['gt','gr'] ],
  GROUP_TOP_LEFT()	=> [ 1,		0,	1,	0,	['gt','gl'] ],
  };

my $border_name = [ 'top', 'bottom', 'left', 'right' ];

sub _css
  {
  my ($c, $id, $group, $border) = @_;

  my $css = '';

  for my $type (0 .. 5)
    {
    my $b = $border_styles->{$type};
  
    # If border eq 'none', this would needlessly repeat the "border: none"
    # from the general group class.
    next if $border eq 'none';

    my $cl = '.' . $b->[4]->[0]; # $cl .= "-$group" unless $group eq '';

    $css .= "table.graph$id $cl {";
    if ($type == GROUP_INNER)
      {
      $css .= " border: none;";			# shorter CSS
      }
    elsif ($type == GROUP_ALL)
      {
      $css .= " border-style: $border;";	# shorter CSS
      }
    else
      {
      for (my $i = 0; $i < 4; $i++)
        {
        $css .= ' border-' . $border_name->[$i] . "-style: $border;" if $b->[$i];
        }
      }
    $css .= "}\n";
    }

  $css;
  }

#############################################################################

sub _init
  {
  # generic init, override in subclasses
  my ($self,$args) = @_;
  
  $self->{class} = 'group';
  $self->{cell_class} = ' gi';
  $self->{name} = '';
  
  $self->{x} = 0;
  $self->{y} = 0;

  # XXX TODO check arguments
  foreach my $k (keys %$args)
    {
    $self->{$k} = $args->{$k};
    }
 
  if (defined $self->{group})
    {
    # register ourselves at this group
    $self->{group}->_add_cell ($self);
    # XXX CHECK also implement sub_class()
    $self->{class} = $self->{group}->{class};
    $self->{class} = 'group' unless defined $self->{class};
    }
 
  $self;
  }

sub _set_type
  {
  # set the proper type of this cell based on the sourrounding cells
  my ($self, $cells) = @_;

  # +------+--------+-------+
  # | LT     TOP      RU    |
  # +      +        +       +
  # | LEFT   INNER    Right |
  # +      +        +       +
  # | LB     BOTTOM   RB    |
  # +------+--------+-------+

  my @coord = (
    [  0, -1, ' gt' ],
    [ +1,  0, ' gr' ],
    [  0, +1, ' gb' ],
    [ -1,  0, ' gl' ],
    );

  my ($sx,$sy) = ($self->{x},$self->{y});

  my $class = '';
  my $gr = $self->{group};
  foreach my $co (@coord)
    {
    my ($x,$y,$c) = @$co; $x += $sx; $y += $sy;
    my $cell = $cells->{"$x,$y"};

    # belongs to the same group?
    my $go = 0; $go = $cell->group() if UNIVERSAL::can($cell, 'group');

    $class .= $c unless defined $go && $gr == $go;
    }

  $class = ' ga' if $class eq ' gt gr gb gl';

  $self->{cell_class} = $class;

  $self;
  }

sub _set_label
  {
  my $self = shift;

  $self->{has_label} = 1;
 
  $self->{name} = $self->{group}->label();
  }

sub shape
  {
  'rect';
  }

sub attribute
  {
  my ($self, $name) = @_;

#  print STDERR "called attribute($name)\n";
#  return $self->{group}->attribute($name);

  my $group = $self->{group};

  return $group->{att}->{$name} if exists $group->{att}->{$name};

  $group->{cache} = {} unless exists $group->{cache};
  $group->{cache}->{att} = {} unless exists $group->{cache}->{att};

  my $cache = $group->{cache}->{att};
  return $cache->{$name} if exists $cache->{$name};

  $cache->{$name} = $group->attribute($name);
  }

use constant isa_cell => 1;

#############################################################################
# conversion to ASCII or HTML

sub as_ascii
  {
  my ($self, $x,$y) = @_;

  my $fb = $self->_framebuffer($self->{w}, $self->{h});

  my $border_style = $self->attribute('borderstyle');
  my $EM = 14;
  # use $self here and not $self->{group} to engage attribute cache:
  my $border_width = Graph::Easy::_border_width_in_pixels($self,$EM);

  # convert overly broad borders to the correct style
  $border_style = 'bold' if $border_width > 2;
  $border_style = 'broad' if $border_width > $EM * 0.2 && $border_width < $EM * 0.75;
  $border_style = 'wide' if $border_width >= $EM * 0.75;

  if ($border_style ne 'none')
    {

    #########################################################################
    # draw our border into the framebuffer

    my $c = $self->{cell_class};
  
    my $b_top = $border_style;
    my $b_left = $border_style;
    my $b_right = $border_style; 
    my $b_bottom = $border_style;
    if ($c !~ 'ga')
      {
      $b_top = 'none' unless $c =~ /gt/;
      $b_left = 'none' unless $c =~ /gl/;
      $b_right = 'none' unless $c =~ /gr/;
      $b_bottom = 'none' unless $c =~ /gb/;
      }

    $self->_draw_border($fb, $b_right, $b_bottom, $b_left, $b_top, $x, $y);
    }

  if ($self->{has_label})
    {
    # include our label

    my $align = $self->attribute('align');
    # the default label cell as a top border, but no left/right border
    my $ys = 0.5;
    $ys = 0 if $border_style eq 'none';
    my $h = $self->{h} - 1; $h ++ if $border_style eq 'none';

    $self->_printfb_aligned ($fb, 0, $ys, $self->{w}, $h, 
	$self->_aligned_label($align), 'middle');
    }

  join ("\n", @$fb);
  }

sub class
  {
  my $self = shift;

  $self->{class} . $self->{cell_class};
  }

#############################################################################

# for rendering this cell as ASCII/Boxart, we need to correct our width based
# on whether we have a border or not. But this is only known after parsing is
# complete.

sub _correct_size
  {
  my ($self,$format) = @_;

  if (!defined $self->{w})
    {
    my $border = $self->attribute('borderstyle');
    $self->{w} = 0;
    $self->{h} = 0;
    # label needs space
    $self->{h} = 1 if $self->{has_label};
    if ($border ne 'none')
      {
      # class "gt", "gb", "gr" or "gr" will be compressed away
      # (e.g. only edge cells will be existant)
      if ($self->{has_label} || ($self->{cell_class} =~ /g[rltb] /))
	{
	$self->{w} = 2;
	$self->{h} = 2;
	}
      elsif ($self->{cell_class} =~ /^ g[rl]\z/)
	{
	$self->{w} = 2;
	}
      elsif ($self->{cell_class} =~ /^ g[bt]\z/)
	{
	$self->{h} = 2;
	}
      }
    }
  if ($self->{has_label})
    {
    my ($w,$h) = $self->dimensions();
    $self->{h} += $h;
    $self->{w} += $w;
    }
  }

1;
__END__

=head1 NAME

Graph::Easy::Group::Cell - A cell in a group

=head1 SYNOPSIS

        use Graph::Easy;

	my $ssl = Graph::Easy::Edge->new( );

	$ssl->set_attributes(
		label => 'encrypted connection',
		style => '-->',
		color => 'red',
	);

	$graph = Graph::Easy->new();

	$graph->add_edge('source', 'destination', $ssl);

	print $graph->as_ascii();

=head1 DESCRIPTION

A C<Graph::Easy::Group::Cell> represents a cell of a group.

Group cells can have a background and, if they are on the outside, a border.

There should be no need to use this package directly.

=head1 METHODS

=head2 error()

	$last_error = $group->error();

	$group->error($error);			# set new messags
	$group->error('');			# clear error

Returns the last error message, or '' for no error.

=head2 as_ascii()

	my $ascii = $cell->as_ascii();

Returns the cell as a little ascii representation.

=head2 as_html()

	my $html = $cell->as_html($tag,$id);

Returns the cell as HTML code.

=head2 label()

	my $label = $cell->label();

Returns the name (also known as 'label') of the cell.

=head2 class()

	my $class = $cell->class();

Returns the classname(s) of this cell, like:

	group_cities gr gb

for a cell with a bottom (gb) and right (gr) border in the class C<cities>.

=head1 EXPORT

None.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2007 by Tels L<http://bloodgate.com>.

See the LICENSE file for more details.

=cut
#############################################################################
# Layout directed graphs on a flat plane. Part of Graph::Easy.
#
# (c) by Tels 2004-2008.
#############################################################################

package Graph::Easy::Layout;

$VERSION = '0.29';

#############################################################################
#############################################################################

package Graph::Easy;

use strict;
require Graph::Easy::Node::Cell;
use Graph::Easy::Edge::Cell qw/
  EDGE_HOR EDGE_VER
  EDGE_CROSS
  EDGE_TYPE_MASK EDGE_MISC_MASK EDGE_NO_M_MASK
  EDGE_SHORT_CELL
 /;

use constant {
  ACTION_NODE	=> 0,	# place node somewhere
  ACTION_TRACE	=> 1,	# trace path from src to dest
  ACTION_CHAIN	=> 2,	# place node in chain (with parent)
  ACTION_EDGES	=> 3,	# trace all edges (shortes connect. first)
  ACTION_SPLICE	=> 4,	# splice in the group fillers
  };

require Graph::Easy::Layout::Chain;		# chain management
use Graph::Easy::Layout::Scout;			# pathfinding
use Graph::Easy::Layout::Repair;		# group cells and splicing/repair
use Graph::Easy::Layout::Path;			# path management

#############################################################################

sub _assign_ranks
  {
  # Assign a rank to each node/group.

  # Afterwards, every node has a rank, these range from 1..infinite for
  # user supplied ranks, and -1..-infinite for automatically found ranks.
  # This lets us later distinguish between autoranks and userranks, while
  # still being able to sort nodes based on their (absolute) rank.
  my $self = shift;

  # a Heap to keep the todo-nodes (aka rank auto or explicit)
  my $todo = Graph::Easy::Heap->new();
  # sort entries based on absolute value
  $todo->sort_sub( sub ($$) { abs($_[0]) <=> abs($_[1]) } );

  # a list of all other nodes
  my @also;

  # XXX TODO:
  # gather elements todo:
  # graph: contained groups, plus non-grouped nodes
  # groups: contained groups, contained nodes

  # sort nodes on their ID to get some basic order
  my @N = $self->sorted_nodes('id');
  push @N, $self->groups();

  my $root = $self->root_node();

  $todo->add([$root->{rank} = -1,$root]) if ref $root;

  # Gather all nodes that have outgoing connections, but no incoming:
  for my $n (@N)
    {
    # we already handled the root node above
    next if $root && $n == $root;

    # if no rank set, use 0 as default
    my $rank_att = $n->raw_attribute('rank');

    $rank_att = undef if defined $rank_att && $rank_att eq 'auto';
    # XXX TODO: this should not happen, the parser should assign an
    # automatic rank ID
    $rank_att = 0 if defined $rank_att && $rank_att eq 'same';

    # user defined ranks range from 1..inf
    $rank_att++ if defined $rank_att;

    # assign undef or 0, 1 etc
    $n->{rank} = $rank_att;

    # user defined ranks are "1..inf", while auto ranks are -1..-inf
    $n->{rank} = -1 if !defined $n->{rank} && $n->predecessors() == 0;

    # push "rank: X;" nodes, or nodes without predecessors
    $todo->add([$n->{rank},$n]) if defined $n->{rank};
    push @also, $n unless defined $n->{rank};
    }

#  print STDERR "# Ranking:\n";
#  for my $n (@{$todo->{_heap}})
#    {
#    print STDERR "# $n->[1]->{name} $n->[0] $n->[1]->{rank}:\n";
#    }
#  print STDERR "# Leftovers in \@also:\n";
#  for my $n (@also)
#    {
#    print STDERR "# $n->{name}:\n";
#    }

  # The above step will create a list of todo nodes that start a chain, but
  # it will miss circular chains like CDEC (e.g. only A appears in todo):
  # A -> B;  C -> D -> E -> C;
  # We fix this as last step

  while ((@also != 0) || $todo->elements() != 0)
    {
    # while we still have nodes to follow
    while (my $elem = $todo->extract_top())
      {
      my ($rank,$n) = @$elem;

      my $l = $n->{rank};

      # If the rank comes from a user-supplied rank, make the next node
      # have an automatic rank (e.g. 4 => -4)
      $l = -$l if $l > 0; 
      # -4 > -5
      $l--;

      for my $o ($n->successors())
        {
        if (!defined $o->{rank})
          {
#	  print STDERR "# set rank $l for $o->{name}\n";
          $o->{rank} = $l;
	  $todo->add([$l,$o]);
          }
        }
      }

    last unless @also;

    while (@also)
      {
      my $n = shift @also;
      # already done? so skip it
      next if defined $n->{rank};

      $n->{rank} = -1; 
      $todo->add([-1, $n]);
      # leave the others for later
      last;
      }

    } # while still something todo

#  print STDERR "# Final ranking:\n";
#  for my $n (@N)
#    {
#    print STDERR "# $n->{name} $n->{rank}:\n";
#    }

  $self;
  }

sub _follow_chain
  {
  # follow the chain from the node
  my ($node) = @_;

  my $self = $node->{graph};

  no warnings 'recursion';

  my $indent = ' ' x (($node->{_chain}->{id} || 0) + 1);
  print STDERR "#$indent Tracking chain from $node->{name}\n" if $self->{debug};

  # create a new chain and point it to the start node
  my $chain = Graph::Easy::Layout::Chain->new( start => $node, graph => $self );
  $self->{chains}->{ $chain->{id} } = $chain;

  my $first_node = $node;
  my $done = 1;				# how many nodes did we process?
 NODE:
  while (3 < 5)
    {
    # Count "unique" successsors, ignoring selfloops, multiedges and nodes
    # in the same chain.

    my $c = $node->{_chain};

    local $node->{_c} = 1;		# stop back-ward loops

    my %suc;

    for my $e (values %{$node->{edges}})
      {
      my $to = $e->{to};

      # ignore self-loops
      next if $e->{from} == $e->{to};

      # XXX TODO
      # skip links from/to groups
      next if $e->{to}->isa('Graph::Easy::Group') ||
              $e->{from}->isa('Graph::Easy::Group');

#      print STDERR "# bidi $e->{from}->{name} to $e->{to}->{name}\n" if $e->{bidirectional} && $to == $node;

      # if it is bidirectional, and points the "wrong" way, turn it around
      $to = $e->{from} if $e->{bidirectional} && $to == $node;

      # edge leads to this node instead from it?
      next if $to == $node;

#      print STDERR "# edge_flow for edge $e", $e->edge_flow() || 'undef' ,"\n";
#      print STDERR "# flow for edge $e", $e->flow() ,"\n";

      # If any of the leading out edges has a flow, stop the chain here
      # This prevents a chain on an edge w/o a flow to be longer and thus
      # come first instead of a flow-edge. But don't stop if there is only
      # one edge:

      if (defined $e->edge_flow())
	{
        %suc = ( $to->{name} => $to );		# empy any possible chain info
        last;
        }

      next if exists $to->{_c};		# backloop into current branch?

      next if defined $to->{_chain} &&	# ignore if it points to the same
		$to->{_chain} == $c; 	# chain (backloop)

      # if the next node's grandparent is the same as ours, it depends on us
      next if $to->find_grandparent() == $node->find_grandparent();

					# ignore multi-edges by dropping
      $suc{$to->{name}} = $to;		# duplicates
      }

    last if keys %suc == 0;		# the chain stopped here

    if (scalar keys %suc == 1)		# have only one unique successor?
      {
      my $s = $suc{ each %suc };

      if (!defined $s->{_chain})	# chain already done?
        {
        $c->add_node( $s );

        $node = $s;			# next node

        print STDERR "#$indent Skipping ahead to $node->{name}\n" if $self->{debug};

        $done++;			# one more
        next NODE;			# skip recursion
        }
      }

    # Select the longest chain from the list of successors
    # and join it with the current one:

    my $max = -1;
    my $next;				# successor
    my $next_chain = undef;

    print STDERR "#$indent $node->{name} successors: \n" if $self->{debug};

    my @rc;

    # for all successors
    #for my $s (sort { $a->{name} cmp $b->{name} || $a->{id} <=> $b->{id} }  values %suc)
    for my $s (values %suc)
      {
      print STDERR "# suc $s->{name} chain ", $s->{_chain} || 'undef',"\n" if $self->{debug};

      $done += _follow_chain($s) 	# track chain
       if !defined $s->{_chain};	# if not already done

      next if $s->{_chain} == $c;	# skip backlinks

      my $ch = $s->{_chain};

      push @rc, [ $ch, $s ];
      # point node to new next node
      ($next_chain, $max, $next) = 
	($ch, $ch->{len}, $s) if $ch->{len} > $max;
      }

    if (defined $next_chain && $self->{debug})
      {
      print STDERR "#   results of tracking successors:\n";
      for my $ch (@rc)
        {
        my ($c,$s) = @$ch;
        my $len = $c->length($s);
        print STDERR "#    chain $c->{id} starting at $c->{start}->{name} (len $c->{len}) ".
                     " pointing to node $s->{name} (len from there: $len)\n";
        }
      print STDERR "# Max chain length is $max (chain id $next_chain->{id})\n";
      }

    if (defined $next_chain)
      {
      print STDERR "#$indent $node->{name} next: " . $next_chain->start()->{name} . "\n" if $self->{debug};

      if ($self->{debug})
	{
	print STDERR "# merging chains\n";
	$c->dump(); $next_chain->dump();
	}

      $c->merge($next_chain, $next)		# merge the two chains
	unless $next == $self->{_root}		# except if the next chain starts with
						# the root node (bug until v0.46)
;#	 || $next_chain->{start} == $self->{_root}; # or the first chain already starts
						# with the root node (bug until v0.47)

      delete $self->{chains}->{$next_chain->{id}} if $next_chain->{len} == 0;
      }

    last;
    }
  
  print STDERR "#$indent Chain $node->{_chain} ended at $node->{name}\n" if $self->{debug};

  $done;				# return nr of done nodes
  }

sub _find_chains
  {
  # Track all node chains (A->B->C etc), trying to find the longest possible
  # node chain. Returns (one of) the root node(s) of the graph.
  my $self = shift;

  print STDERR "# Tracking chains\n" if $self->{debug};

  # drop all old chain info
  $self->{_chains} = { };
  $self->{_chain} = 0;					# new chain ID

  # For all not-done-yet nodes, track the chain starting with that node.

  # compute predecessors for all nodes: O(1)
  my $p;
  my $has_origin = 0;
  foreach my $n (values %{$self->{nodes}}, values %{$self->{groups}})
#  for my $n (values %{$self->{nodes}})
    {
    $n->{_chain} = undef;				# reset chain info
    $has_origin = 0;
    $has_origin = 1 if defined $n->{origin} && $n->{origin} != $n;
    $p->{$n->{name}} = [ $n->has_predecessors(), $has_origin, abs($n->{rank}) ];
    }

  my $done = 0; my $todo = scalar keys %{$self->{nodes}};

  # the node where the layout should start, as name
  my $root_name = $self->{attr}->{root};
  $self->{_root} = undef;				# as ref to a Node object

  # Start at nodes with no predecessors (starting points) and then do the rest:
  for my $name ($root_name, sort {
    my $aa = $p->{$a};
    my $bb = $p->{$b};

    # sort first on rank
    $aa->[2] <=> $bb->[2] ||
    # nodes that have an origin come last
    $aa->[1] <=> $bb->[1] ||
    # nodes with no predecessorts are to be prefered 
    $aa->[0] <=> $bb->[0] ||
    # last resort, alphabetically sorted
    $a cmp $b 
   } keys %$p)
    {
    next unless defined $name;		# in case no root was set, first entry
					# will be undef and must be skipped
    my $n = $self->{nodes}->{$name};

#    print STDERR "# tracing chain from $name (", join(", ", @{$p->{$name}}),")\n";

    # store root node unless already found, is accessed in _follow_chain()
    $self->{_root} = $n unless defined $self->{_root};

    last if $done == $todo;			# already processed all nodes?

    # track the chain unless already done and count number of nodes done
    $done += _follow_chain($n) unless defined $n->{_chain};
    }

  print STDERR "# Oops - done only $done nodes, but should have done $todo.\n" if $done != $todo && $self->{debug};
  print STDERR "# Done all $todo nodes.\n" if $done == $todo && $self->{debug};

  $self->{_root};
  }

#############################################################################
# debug

sub _dump_stack
  {
  my ($self, @todo) = @_;

  print STDERR "# Action stack contains ", scalar @todo, " steps:\n";
  for my $action (@todo)
    {
    my $action_type = $action->[0];
    if ($action_type == ACTION_NODE)
      {
      my ($at,$node,$try,$edge) = @$action;
      my $e = ''; $e = " on edge $edge->{id}" if defined $edge;
      print STDERR "#  place '$node->{name}' with try $try$e\n";
      }
    elsif ($action_type == ACTION_CHAIN)
      {
      my ($at, $node, $try, $parent, $edge) = @$action;
      my $id = 'unknown'; $id = $edge->{id} if ref($edge);
      print STDERR
       "#  chain '$node->{name}' from parent '$parent->{name}' with try $try (for edge id $id)'\n";
      }
    elsif ($action_type == ACTION_TRACE)
      {
      my ($at,$edge) = @$action;
      my ($src,$dst) = ($edge->{from}, $edge->{to});
      print STDERR
       "#  trace '$src->{name}' to '$dst->{name}' via edge $edge->{id}\n";
      }
    elsif ($action_type == ACTION_EDGES)
      {
      my $at = shift @$action;
      print STDERR
       "#  tracing the following edges, shortest and with flow first:\n";

      }
    elsif ($action_type == ACTION_SPLICE)
      {
      my ($at) = @$action;
      print STDERR
       "#  splicing in group filler cells\n";
      }
    }
  }

sub _action
  {
  # generate an action for the action stack toplace a node
  my ($self, $action, $node, @params) = @_;

  # mark the node as already done
  delete $node->{_todo};

  # mark all children of $node as processed, too, because they will be
  # placed at the same time:
  $node->_mark_as_placed() if keys %{$node->{children}} > 0;

  [ $action, $node, @params ];
  }

#############################################################################
# layout the graph

# The general layout routine for the entire graph:

sub layout
  {
  my $self = shift;

  # ( { type => 'force' } )
  my $args = $_[0];
  # ( type => 'force' )
  $args = { @_ } if @_ > 1;

  my $type = 'adhoc';
  $type = 'force' if $args->{type} && $args->{type} eq 'force';

  # protect the layout with a timeout, unless run under the debugger:
  eval {
    local $SIG{ALRM} = sub { die "layout did not finish in time\n" };
    alarm(abs( $args->{timeout} || $self->{timeout} || 5))
	unless defined $DB::single; # no timeout under the debugger

    print STDERR "#\n# Starting $type-based layout.\n" if $self->{debug};

    # Reset the sequence of the random generator, so that for the same
    # seed, the same layout will occur. Both for testing and repeatable
    # layouts based on max score.
    srand($self->{seed});

    if ($type eq 'force')
      {
      require Graph::Easy::Layout::Force;
      $self->error("Force-directed layouts are not yet implemented.");
      $self->_layout_force();
      }
    else
      {
      $self->_edges_into_groups();

      $self->_layout();
      }

    };					# eval {}; -- end of timeout protected code

  alarm(0);				# disable alarm

  # cleanup
  $self->{chains} = undef;		# drop chain info
  foreach my $n (values %{$self->{nodes}}, values %{$self->{groups}})
    {
    # drop old chain info
    $n->{_next} = undef;
    delete $n->{_chain};
    delete $n->{_c};
    }

  delete $self->{_root};

  die $@ if $@;				# propagate errors
  }

sub _drop_caches
  {
  # before the layout phase, we drop cached information from the last run
  my $self = shift;

  for my $n (values %{$self->{nodes}})
    {
    # XXX after we laid out the individual groups:    
    # skip nodes that are not part of the current group
    #next if $n->{group} && !$self->{graph};

    # empty the cache of computed values (flow, label, border etc)
    $n->{cache} = {};

    $n->{x} = undef; $n->{y} = undef;	# mark every node as not placed yet
    $n->{w} = undef;			# force size recalculation
    $n->{_todo} = undef;		# mark as todo
    }
  for my $g (values %{$self->{groups}})
    {
    $g->{x} = undef; $g->{y} = undef;	# mark every group as not placed yet
    $g->{_todo} = undef;		# mark as todo
    }
  }

sub _layout
  {
  my $self = shift;

  ###########################################################################
  # do some assorted stuff beforehand

  print STDERR "# Doing layout for ", 
	(defined $self->{name} ? 'group ' . $self->{name} : 'main graph'),
	"\n" if $self->{debug};

  # XXX TODO: 
  # for each primary group
#  my @groups = $self->groups_within(0);
#
#  if (@groups > 0 && $self->{debug})
#    {
#    print STDERR "# Found the following top-level groups:\n";
#    for my $g (@groups)
#      {
#      print STDERR "# $g $g->{name}\n";
#      }
#    }
#
#  # layout each group on its own, recursively:
#  foreach my $g (@groups)
#    {
#    $g->_layout();
#    }

  # finally assembly everything together

  $self->_drop_caches();

  local $_; $_->_grow() for values %{$self->{nodes}};

  $self->_assign_ranks();

  # find (longest possible) chains of nodes to "straighten" graph
  my $root = $self->_find_chains();

  ###########################################################################
  # prepare our stack of things we need to do before we are finished

  # action stack, place root 1st if it is known
  my @todo = $self->_action( ACTION_NODE, $root, 0 ) if ref $root;

  if ($self->{debug})
    {
    print STDERR "#  Generated the following chains:\n";
    for my $chain (
     sort { $a->{len} <=> $b->{len} || $a->{start}->{name} cmp $b->{start}->{name} }
      values %{$self->{chains}})
      {
      $chain->dump('  ');
      }
    }

  # mark all edges as unprocessed, so that we do not process them twice
  for my $edge (values %{$self->{edges}})
    { 
    $edge->_clear_cells();
    $edge->{_todo} = undef;		# mark as todo
    }

  # XXX TODO:
  # put all chains on heap (based on their len)
  # take longest chain, resolve it and all "connected" chains, repeat until
  # heap is empty

  for my $chain (sort { 

     # chain starting at root first
     (($b->{start} == $root) <=> ($a->{start} == $root)) ||

     # longest chains first
     ($b->{len} <=> $a->{len}) ||

     # chains on nodes that do have an origin come later
     (defined($a->{start}->{origin}) <=> defined ($b->{start}->{origin})) ||

     # last resort, sort on name of the first node in chain
     ($a->{start}->{name} cmp $b->{start}->{name}) 

     } values %{$self->{chains}})
    {
    print STDERR "# laying out chain $chain->{id} (len $chain->{len})\n" if $self->{debug};

    # layout the chain nodes, then resolve inter-chain links, then traverse
    # chains recursively
    push @todo, @{ $chain->layout() } unless $chain->{_done};
    }

  print STDERR "# Done laying out all chains, doing left-overs:\n" if $self->{debug};

  $self->_dump_stack(@todo) if $self->{debug};

  # After laying out all chained nodes and their links, we need to resolve
  # left-over edges and links. We do this for each node, and then for each of
  # its edges, but do the edges shortest-first.
 
  for my $n (values %{$self->{nodes}})
    {
    push @todo, $self->_action( ACTION_NODE, $n, 0 ); # if exists $n->{_todo};

    # gather to-do edges
    my @edges = ();
    for my $e (sort { $a->{to}->{name} cmp $b->{to}->{name} } values %{$n->{edges}})
#    for my $e (values %{$n->{edges}})
      {
      # edge already done?
      next unless exists $e->{_todo};

      # skip links from/to groups
      next if $e->{to}->isa('Graph::Easy::Group') ||
              $e->{from}->isa('Graph::Easy::Group');

      push @edges, $e;
      delete $e->{_todo};
      }
    # XXX TODO: This does not work, since the nodes are not yet laid out
    # sort them on their shortest distances
#    @edges = sort { $b->_distance() <=> $a->_distance() } @edges;

    # put them on the action stack in that order
    for my $e (@edges)
      {
      push @todo, [ ACTION_TRACE, $e ];
#      print STDERR "do $e->{from}->{name} to $e->{to}->{name} ($e->{id} " . $e->_distance().")\n";
#      push @todo, [ ACTION_CHAIN, $e->{to}, 0, $n, $e ];
      }
    }

  print STDERR "# Done laying out left-overs.\n" if $self->{debug};

  # after laying out all inter-group nodes and their edges, we need to splice in the
  # group cells
  if (scalar $self->groups() > 0)
    {
    push @todo, [ ACTION_SPLICE ] if scalar $self->groups();

    # now do all group-to-group and node-to-group and group-to-node links:
    for my $n (values %{$self->{groups}})
      {
      }
    }

  $self->_dump_stack(@todo) if $self->{debug};

  ###########################################################################
  # prepare main backtracking-loop

  my $score = 0;			# overall score
  $self->{cells} = { };			# cell array (0..x,0..y)
  my $cells = $self->{cells};

  print STDERR "# Start\n" if $self->{debug};

  $self->{padding_cells} = 0;		# set to false (no filler cells yet)

  my @done = ();			# stack with already done actions
  my $step = 0;
  my $tries = 16;

  # store for each rank the initial row/coluumn
  $self->{_rank_pos} = {};
  # does rank_pos store rows or columns?
  $self->{_rank_coord} = 'y';
  my $flow = $self->flow();
  $self->{_rank_coord} = 'x' if $flow == 0 || $flow == 180;

  TRY:
  while (@todo > 0)			# all actions on stack done?
    {
    $step ++;

    if ($self->{debug} && ($step % 1)==0)
      {
      my ($nodes,$e_nodes,$edges,$e_edges) = $self->_count_done_things();
      print STDERR "# Done $nodes nodes and $edges edges.\n";
      #$self->{debug} = 2 if $nodes > 243;
      return if ($nodes > 230);
      }

    # pop one action and mark it as done
    my $action = shift @todo; push @done, $action;

    # get the action type (ACTION_NODE etc)
    my $action_type = $action->[0];

    my ($src, $dst, $mod, $edge);

    if ($action_type == ACTION_NODE)
      {
      my (undef, $node,$try,$edge) = @$action;
      print STDERR "# step $step: action place '$node->{name}' (try $try)\n" if $self->{debug};

      $mod = 0 if defined $node->{x};
      # $action is node to be placed, generic placement at "random" location
      $mod = $self->_find_node_place( $node, $try, undef, $edge) unless defined $node->{x};
      }
    elsif ($action_type == ACTION_CHAIN)
      {
      my (undef, $node,$try,$parent, $edge) = @$action;
      print STDERR "# step $step: action chain '$node->{name}' from parent '$parent->{name}'\n" if $self->{debug};

      $mod = 0 if defined $node->{x};
      $mod = $self->_find_node_place( $node, $try, $parent, $edge ) unless defined $node->{x};
      }
    elsif ($action_type == ACTION_TRACE)
      {
      # find a path to the target node
      ($action_type,$edge) = @$action;

      $src = $edge->{from}; $dst = $edge->{to};

      print STDERR "# step $step: action trace '$src->{name}' => '$dst->{name}'\n" if $self->{debug};

      if (!defined $dst->{x})
        {
#	warn ("Target node $dst->{name} not yet placed");
        $mod = $self->_find_node_place( $dst, 0, undef, $edge );
	}        
      if (!defined $src->{x})
        {
#	warn ("Source node $src->{name} not yet placed");
        $mod = $self->_find_node_place( $src, 0, undef, $edge );
	}        

      # find path (mod is score modifier, or undef if no path exists)
      $mod = $self->_trace_path( $src, $dst, $edge );
      }
    elsif ($action_type == ACTION_SPLICE)
      {
      # fill in group info and return
      $self->_fill_group_cells($cells) unless $self->{error};
      $mod = 0;
      }
    else
      {
      require Carp;
      Carp::confess ("Illegal action $action->[0] on TODO stack");
      }

    if (!defined $mod)
      {
      # rewind stack
      if (($action_type == ACTION_NODE || $action_type == ACTION_CHAIN))
        { 
        print STDERR "# Step $step: Rewind stack for $action->[1]->{name}\n" if $self->{debug};

        # undo node placement and free all cells
        $action->[1]->_unplace() if defined $action->[1]->{x};
        $action->[2]++;		# increment try for placing
        $tries--;
	last TRY if $tries == 0;
        }
      else
        {
        print STDERR "# Step $step: Rewind stack for path from $src->{name} to $dst->{name}\n" if $self->{debug};
    
        # if we couldn't find a path, we need to rewind one more action (just
	# redoing the path would would fail again!)

#        unshift @todo, pop @done;
#        unshift @todo, pop @done;

#        $action = $todo[0];
#        $action_type = $action->[0];

#        $self->_dump_stack(@todo);
#
#        if (($action_type == ACTION_NODE || $action_type == ACTION_CHAIN))
#          {
#          # undo node placement
#          $action->[1]->_unplace();
#          $action->[2]++;		# increment try for placing
#          }
  	$tries--;
	last TRY if $tries == 0;
        next TRY;
        } 
      unshift @todo, $action;
      next TRY;
      } 

    $score += $mod;
    print STDERR "# Step $step: Score is $score\n\n" if $self->{debug};
    }

    $self->{score} = $score;			# overall score

#  if ($tries == 0)
    {
    my ($nodes,$e_nodes,$edges,$e_edges) = $self->_count_done_things();
    if  ( ($nodes != $e_nodes) ||
          ($edges != $e_edges) )
      {
      $self->warn( "Layouter could only place $nodes nodes/$edges edges out of $e_nodes/$e_edges - giving up");
      }
     else
      {
      $self->_optimize_layout();
      }
    }
    # all things on the stack were done, or we encountered an error
  }

sub _count_done_things
  {
  my $self = shift;

  # count placed nodes
  my $nodes = 0;
  my $i = 1;
  for my $n (values %{$self->{nodes}})
    {
    $nodes++ if defined $n->{x};
    }
  my $edges = 0;
  $i = 1;
  # count fully routed edges
  for my $e (values %{$self->{edges}})
    {
    $edges++ if scalar @{$e->{cells}} > 0 && !exists $e->{_todo};
    }
  my $e_nodes = scalar keys %{$self->{nodes}};
  my $e_edges = scalar keys %{$self->{edges}};
  return ($nodes,$e_nodes,$edges,$e_edges);
  }

my $size_name = {
  EDGE_HOR() => [ 'cx', 'x' ],
  EDGE_VER() => [ 'cy', 'y' ]
  };

sub _optimize_layout
  {
  my $self = shift;

  # optimize the finished layout

  my $all_cells = $self->{cells};

  ###########################################################################
  # for each edge, compact HOR and VER stretches of cells
  for my $e (values %{$self->{edges}})
    {
    my $cells = $e->{cells};

    # there need to be at least two cells for us to be able to combine them
    next if @$cells < 2;

    print STDERR "# Compacting edge $e->{from}->{name} to $e->{to}->{name}\n"
      if $self->{debug};

    my $f = $cells->[0]; my $i = 1;
    my ($px, $py);		# coordinates of the placeholder cell
    while ($i < @$cells)
      {
      my $c = $cells->[$i++];

#      print STDERR "#  at $f->{type} $f->{x},$f->{y}  (next: $c->{type} $c->{x},$c->{y})\n";

      my $t1 = $f->{type} & EDGE_NO_M_MASK;
      my $t2 = $c->{type} & EDGE_NO_M_MASK;

      # > 0: delete that cell: 1 => reverse order, 2 => with hole
      my $delete = 0;

      # compare $first to $c
      if ($t1 == $t2 && ($t1 == EDGE_HOR || $t1 == EDGE_VER))
        {
#	print STDERR "#  $i: Combining them.\n";

	# check that both pieces are continues (e.g. with a cross section,
	# the other edge has a hole in the cell array)

	# if the second cell has a misc (label, short) flag, carry it over
        $f->{type} += $c->{type} & EDGE_MISC_MASK;

        # which size/coordinate to modify
	my ($m,$co) = @{ $size_name->{$t1} };

#	print STDERR "# Combining edge cells $f->{x},$f->{y} and $c->{x},$c->{y}\n";

	# new width/height is the combined size
	$f->{$m} = ($f->{$m} || 1) + ($c->{$m} || 1);

#	print STDERR "# Result $f->{x},$f->{y} ",$f->{cx}||1," ", $f->{cy}||1,"\n";

	# drop the reference from the $cells array for $c
	delete $all_cells->{ "$c->{x},$c->{y}" };

        ($px, $py) = ($c->{x}, $c->{y});
	if ($f->{$co} > $c->{$co})
	  {
	  # remember coordinate of the moved cell for the placeholder
          ($px, $py) = ($f->{x}, $f->{y});

	  # move $f to the new place if it was modified
	  delete $all_cells->{ "$f->{x},$f->{y}" };
	  # correct start coordinate for reversed order
	  $f->{$co} -= ($c->{$m} || 1);

	  $all_cells->{ "$f->{x},$f->{y}" } = $f;
	  }

	$delete = 1;				# delete $c
	}

      # remove that cell, but start combining at next
#      print STDERR "# found hole at $i\n" if $c->{type} == EDGE_HOLE;

      $delete = 2 if $c->{type} == EDGE_HOLE;
      if ($delete)
	{
        splice (@{$e->{cells}}, $i-1, 1);		# remove from the edge
	if ($delete == 1)
	  {
	  my $xy = "$px,$py";
	  # replace with placeholder (important for HTML output)
	  $all_cells->{$xy} = Graph::Easy::Edge::Cell::Empty->new (
	    x => $px, y => $py,
	  ) unless $all_cells->{$xy};	

          $i--; $c = $f;				# for the next statement
	  }
	else { $c = $cells->[$i-1]; }
        }
      $f = $c;
      }

#   $i = 0;
#   while ($i < @$cells)
#     {
#     my $c = $cells->[$i];
#     print STDERR "#   $i: At $c->{type} $c->{x},$c->{y}  ", $c->{cx}||1, " ", $c->{cy} || 1,"\n";
#     $i++;
#     }

    }
  print STDERR "# Done compacting edges.\n" if $self->{debug};

  }

1;
__END__

=head1 NAME

Graph::Easy::Layout - Layout the graph from Graph::Easy

=head1 SYNOPSIS

	use Graph::Easy;
	
	my $graph = Graph::Easy->new();

	my $bonn = Graph::Easy::Node->new(
		name => 'Bonn',
	);
	my $berlin = Graph::Easy::Node->new(
		name => 'Berlin',
	);

	$graph->add_edge ($bonn, $berlin);

	$graph->layout();

	print $graph->as_ascii( );

	# prints:

	# +------+     +--------+
	# | Bonn | --> | Berlin |
	# +------+     +--------+

=head1 DESCRIPTION

C<Graph::Easy::Layout> contains just the actual layout code for
L<Graph::Easy|Graph::Easy>.

=head1 METHODS

C<Graph::Easy::Layout> injects the following methods into the C<Graph::Easy>
namespace:

=head2 layout()

	$graph->layout();

Layout the actual graph.

=head2 _assign_ranks()

	$graph->_assign_ranks();

Used by C<layout()> to assign each node a rank, so they can be sorted
and grouped on these.

=head2 _optimize_layout

Used by C<layout()> to optimize the layout as a last step.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2008 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut
#############################################################################
# One chain of nodes in a Graph::Easy - used internally for layouts.
#
# (c) by Tels 2004-2006. Part of Graph::Easy
#############################################################################

package Graph::Easy::Layout::Chain;

use Graph::Easy::Base;
$VERSION = '0.09';
@ISA = qw/Graph::Easy::Base/;

use strict;

use constant {
  _ACTION_NODE  => 0, # place node somewhere
  _ACTION_TRACE => 1, # trace path from src to dest
  _ACTION_CHAIN => 2, # place node in chain (with parent)
  _ACTION_EDGES => 3, # trace all edges (shortes connect. first)
  };

#############################################################################

sub _init
  {
  # Generic init routine, to be overriden in subclasses.
  my ($self,$args) = @_;
  
  foreach my $k (keys %$args)
    {
    if ($k !~ /^(start|graph)\z/)
      {
      require Carp;
      Carp::confess ("Invalid argument '$k' passed to __PACKAGE__->new()");
      }
    $self->{$k} = $args->{$k};
    }
 
  $self->{end} = $self->{start};
 
  # store chain at node (to lookup node => chain info)
  $self->{start}->{_chain} = $self;
  $self->{start}->{_next} = undef;

  $self->{len} = 1;

  $self;
  }

sub start
  {
  # return first node in the chain
  my $self = shift;

  $self->{start};
  }

sub end
  {
  # return last node in the chain
  my $self = shift;

  $self->{end};
  }

sub add_node
  {
  # add a node at the end of the chain
  my ($self, $node) = @_;

  # store at end
  $self->{end}->{_next} = $node;
  $self->{end} = $node;

  # store chain at node (to lookup node => chain info)
  $node->{_chain} = $self;
  $node->{_next} = undef;
  
  $self->{len} ++;

  $self;
  }

sub length
  {
  # Return the length of the chain in nodes. Takes optional
  # node from where to calculate length.
  my ($self, $node) = @_;

  return $self->{len} unless defined $node;

  my $len = 0;
  while (defined $node)
    {
    $len++; $node = $node->{_next};
    }

  $len;
  }

sub nodes
  {
  # return all the nodes in the chain as a list, in order.
  my $self = shift;

  my @nodes = ();
  my $n = $self->{start};
  while (defined $n)
    {
    push @nodes, $n;
    $n = $n->{_next};
    }

  @nodes;
  }

sub layout
  {
  # Return an action stack containing the nec. actions to
  # lay out the nodes in the chain, plus any connections between
  # them.
  my ($self, $edge) = @_;

  # prevent doing it twice 
  return [] if $self->{_done}; $self->{_done} = 1;

  my @TODO = ();

  my $g = $self->{graph};

  # first, layout all the nodes in the chain:

  # start with first node
  my $pre = $self->{start}; my $n = $pre->{_next};
  if (exists $pre->{_todo})
    {
    # edges with a flow attribute must be handled differently
    # XXX TODO: the test for attribute('flow') might be wrong (raw_attribute()?)
    if ($edge && ($edge->{to} == $pre) && ($edge->attribute('flow') || $edge->has_ports()))
      {
      push @TODO, $g->_action( _ACTION_CHAIN, $pre, 0, $edge->{from}, $edge);
      }
    else
      {
      push @TODO, $g->_action( _ACTION_NODE, $pre, 0, $edge );
      }
    }

  print STDERR "# Stack after first:\n" if $g->{debug};
  $g->_dump_stack(@TODO) if $g->{debug};

  while (defined $n)
    {
    if (exists $n->{_todo})
      {
      # CHAIN means if $n isn't placed yet, it will be done with
      # $pre as parent:

      # in case there are multiple edges to the target node, use the first
      # one to determine the flow:
      my @edges = $g->edge($pre,$n);

      push @TODO, $g->_action( _ACTION_CHAIN, $n, 0, $pre, $edges[0] );
      }
    $pre = $n;
    $n = $n->{_next};
    }

  print STDERR "# Stack after chaining:\n" if $g->{debug};
  $g->_dump_stack(@TODO) if $g->{debug};

  # link from each node to the next
  $pre = $self->{start}; $n = $pre->{_next};
  while (defined $n)
    {
    # first do edges going from P to N
    #for my $e (sort { $a->{to}->{name} cmp $b->{to}->{name} } values %{$pre->{edges}})
    for my $e (values %{$pre->{edges}})
      {
      # skip selfloops and backward links, these will be done later
      next if $e->{to} != $n;

      next unless exists $e->{_todo};

      # skip links from/to groups
      next if $e->{to}->isa('Graph::Easy::Group') ||
              $e->{from}->isa('Graph::Easy::Group');

#      # skip edges with a flow
#      next if exists $e->{att}->{start} || exist $e->{att}->{end};

      push @TODO, [ _ACTION_TRACE, $e ];
      delete $e->{_todo};
      }

    } continue { $pre = $n; $n = $n->{_next}; }

  print STDERR "# Stack after chain-linking:\n" if $g->{debug};
  $g->_dump_stack(@TODO) if $g->{debug};

  # Do all other links inside the chain (backwards, going forward more than
  # one node etc)

  $n = $self->{start};
  while (defined $n)
    {
    my @edges;

    my @count;

    print STDERR "# inter-chain link from $n->{name}\n" if $g->{debug};

    # gather all edges starting at $n, but do the ones with a flow first
#    for my $e (sort { $a->{to}->{name} cmp $b->{to}->{name} } values %{$n->{edges}})
    for my $e (values %{$n->{edges}})
      {
      # skip selfloops, these will be done later
      next if $e->{to} == $n;

      next if !ref($e->{to}->{_chain});
      next if !ref($e->{from}->{_chain});

      next if $e->has_ports();

      # skip links from/to groups
      next if $e->{to}->isa('Graph::Easy::Group') ||
              $e->{from}->isa('Graph::Easy::Group');

      print STDERR "# inter-chain link from $n->{name} to $e->{to}->{name}\n" if $g->{debug};

      # leaving the chain?
      next if $e->{to}->{_chain} != $self;

#      print STDERR "#    trying for $n->{name}:\t $e->{from}->{name} to $e->{to}->{name}\n";
      next unless exists $e->{_todo};

      # calculate for this edge, how far it goes
      my $count = 0;
      my $curr = $n;
      while (defined $curr && $curr != $e->{to})
        {
        $curr = $curr->{_next}; $count ++;
        }
      if (!defined $curr)
        {
        # edge goes backward

        # start at $to
        $curr = $e->{to};
        $count = 0;
        while (defined $curr && $curr != $e->{from})
          {
          $curr = $curr->{_next}; $count ++;
          }
        $count = 100000 if !defined $curr;	# should not happen
        }
      push @edges, [ $count, $e ];
      push @count, [ $count, $e->{from}->{name}, $e->{to}->{name} ];
      }

#    use Data::Dumper; print STDERR "count\n", Dumper(@count);

    # do edges, shortest first 
    for my $e (sort { $a->[0] <=> $b->[0] } @edges)
      {
      push @TODO, [ _ACTION_TRACE, $e->[1] ];
      delete $e->[1]->{_todo};
      }

    $n = $n->{_next};
    }
 
  # also do all selfloops on $n
  $n = $self->{start};
  while (defined $n)
    {
#    for my $e (sort { $a->{to}->{name} cmp $b->{to}->{name} } values %{$n->{edges}})
    for my $e (values %{$n->{edges}})
      {
      next unless exists $e->{_todo};

#      print STDERR "# $e->{from}->{name} to $e->{to}->{name} on $n->{name}\n";
#      print STDERR "# ne $e->{to} $n $e->{id}\n" 
#       if $e->{from} != $n || $e->{to} != $n;		# no selfloop?

      next if $e->{from} != $n || $e->{to} != $n;	# no selfloop?

      push @TODO, [ _ACTION_TRACE, $e ];
      delete $e->{_todo};
      }
    $n = $n->{_next};
    }

  print STDERR "# Stack after self-loops:\n" if $g->{debug};
  $g->_dump_stack(@TODO) if $g->{debug};

  # XXX TODO
  # now we should do any links that start or end at this chain, recursively

  $n = $self->{start};
  while (defined $n)
    {

    # all chains that start at this node
    for my $e (sort { $a->{to}->{name} cmp $b->{to}->{name} } values %{$n->{edges}})
      {
      my $to = $e->{to};

      # skip links to groups
      next if $to->isa('Graph::Easy::Group');

#      print STDERR "# chain-tracking to: $to->{name} $to->{_chain}\n";

      next unless exists $to->{_chain} && ref($to->{_chain}) =~ /Chain/;
      my $chain = $to->{_chain};
      next if $chain->{_done};

#      print STDERR "# chain-tracking to: $to->{name}\n";

      # pass the edge along, in case it has a flow
#      my @pass = ();
#      push @pass, $e if $chain->{_first} && $e->{to} == $chain->{_first};
      push @TODO, @{ $chain->layout($e) } unless $chain->{_done};

      # link the edges to $to
      next unless exists $e->{_todo};	# was already done above?

      # next if $e->has_ports();

      push @TODO, [ _ACTION_TRACE, $e ];
      delete $e->{_todo};
      }
    $n = $n->{_next};
    }
 
  \@TODO;
  }

sub dump
  {
  # dump the chain to STDERR
  my ($self, $indent) = @_;

  $indent = '' unless defined $indent;

  print STDERR "#$indent chain id $self->{id} (len $self->{len}):\n";
  print STDERR "#$indent is empty\n" and return if $self->{len} == 0;

  my $n = $self->{start};
  while (defined $n)
    {
    print STDERR "#$indent  $n->{name} (chain id: $n->{_chain}->{id})\n";
    $n = $n->{_next};
    }
  $self;
  }

sub merge
  {
  # take another chain, and merge it into ourselves. If $where is defined,
  # absorb only the nodes from $where onwards (instead of all of them).
  my ($self, $other, $where) = @_;

  my $g = $self->{graph};

  print STDERR "# panik: ", join(" \n",caller()),"\n" if !defined $other;

  print STDERR 
   "# Merging chain $other->{id} (len $other->{len}) into $self->{id} (len $self->{len})\n"
     if $g->{debug};

  print STDERR 
   "# Merging from $where->{name} onwards\n"
     if $g->{debug} && ref($where);
 
  # cannot merge myself into myself (without allocating infinitely memory)
  return if $self == $other;

  # start at start as default
  $where = undef unless ref($where) && exists $where->{_chain} && $where->{_chain} == $other;

  $where = $other->{start} unless defined $where;
  
  # make all nodes from chain #1 belong to it (to detect loops)
  my $n = $self->{start};
  while (defined $n)
    {
    $n->{_chain} = $self;
    $n = $n->{_next};
    }

  print STDERR "# changed nodes\n" if $g->{debug};
  $self->dump() if $g->{debug};

  # terminate at $where
  $self->{end}->{_next} = $where;
  $self->{end} = $other->{end};

  # start at joiner
  $n = $where;
  while (ref($n))
    {
    $n->{_chain} = $self;
    my $pre = $n;
    $n = $n->{_next};

#    sleep(1);
#    print "# at $n->{name} $n->{_chain}\n" if ref($n);
    if (ref($n) && defined $n->{_chain} && $n->{_chain} == $self)	# already points into ourself?
      {
#      sleep(1);
#      print "# pre $pre->{name} $pre->{_chain}\n";
      $pre->{_next} = undef;	# terminate
      $self->{end} = $pre;
      last;
      }
    }

  # could speed this up
  $self->{len} = 0; $n = $self->{start};
  while (defined $n)
    {
    $self->{len}++; $n = $n->{_next};
    }

#  print "done merging, dumping result:\n";
#  $self->dump(); sleep(10);

  if (defined $other->{start} && $where == $other->{start})
    {
    # we absorbed the other chain completely, so drop it
    $other->{end} = undef;
    $other->{start} = undef;
    $other->{len} = 0;
    # caller is responsible for cleaning it up
    }

  print STDERR "# after merging\n" if $g->{debug};
  $self->dump() if $g->{debug};

  $self;
  }

1;
__END__

=head1 NAME

Graph::Easy::Layout::Chain - Chain of nodes for layouter

=head1 SYNOPSIS

	# used internally, do not use directly

        use Graph::Easy;
        use Graph::Easy::Layout::Chain;

	my $graph = Graph::Easy->new( );
	my ($node, $node2) = $graph->add_edge( 'A', 'B' );

	my $chain = Graph::Easy::Layout::Chain->new(
		start => $node,
		graph => $graph, );

	$chain->add_node( $node2 );

=head1 DESCRIPTION

A C<Graph::Easy::Layout::Chain> object represents a chain of nodes
for the layouter.

=head1 METHODS

=head2 new()

        my $chain = Graph::Easy::Layout::Chain->new( start => $node );

Create a new chain and set its starting node to C<$node>.

=head2 length()

	my $len = $chain->length();

Return the length of the chain, in nodes.

	my $len = $chain->length( $node );

Given an optional C<$node> as argument, returns the length
from that node onwards. For the chain with the three nodes
A, B and C would return 3, 2, and 1 for A, B and C, respectively.

Returns 0 if the passed node is not part of this chain.

=head2 nodes()

	my @nodes = $chain->nodes();

Return all the node objects in the chain as list, in order.

=head2 add_node()

	$chain->add_node( $node );

Add C<$node> to the end of the chain.

=head2 start()

	my $node = $chain->start();

Return first node in the chain.

=head2 end()

	my $node = $chain->end();

Return last node in the chain.

=head2 layout()

	my $todo = $chain->layout();

Return an action stack as array ref, containing the nec. actions to 
layout the chain (nodes, plus interlinks in the chain).

Will recursively traverse all chains linked to this chain.

=head2 merge()

	my $chain->merge ( $other_chain );
	my $chain->merge ( $other_chain, $where );

Merge the other chain into ourselves, adding its nodes at our end.
The other chain is emptied and must be deleted by the caller.
  
If C<$where> is defined and a member of C<$other_chain>, absorb only the
nodes from C<$where> onwards, instead of all of them.

=head2 error()

	$last_error = $node->error();

	$node->error($error);			# set new messags
	$node->error('');			# clear error

Returns the last error message, or '' for no error.

=head2 dump()

	$chain->dump();

Dump the chain to STDERR, to aid debugging.

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Graph::Easy>, L<Graph::Easy::Layout>.

=head1 AUTHOR

Copyright (C) 2004 - 2006 by Tels L<http://bloodgate.com>.

See the LICENSE file for more details.

=cut
#############################################################################
# Force-based layouter for Graph::Easy.
#
# (c) by Tels 2004-2007.
#############################################################################

package Graph::Easy::Layout::Force;

$VERSION = '0.01';

#############################################################################
#############################################################################

package Graph::Easy;

use strict;

sub _layout_force
  {
  # Calculate for each node the force on it, then move them accordingly.
  # When things have settled, stop.
  my ($self) = @_;

  # For each node, calculate the force actiing on it, seperated into two
  # components along the X and Y axis:

  # XXX TODO: replace with all contained nodes + groups
  my @nodes = $self->nodes();

  return if @nodes == 0;

  my $root = $self->root_node();

  if (!defined $root)
    {
    # find a suitable root node
    $root = $nodes[0];
    }

  # this node never moves
  $root->{_pinned} = undef;
  $root->{x} = 0;
  $root->{y} = 0;

  # get the "gravity" force
  my $gx = 0; my $gy = 0;

  my $flow = $self->flow();
  if ($flow == 0)
    {
    $gx = 1;
    }
  elsif ($flow == 90)
    {
    $gy = -1;
    }
  elsif ($flow == 270)
    {
    $gy = 1;
    }
  else # ($flow == 180)
    {
    $gx = -1;
    }

  my @particles;
  # set initial positions
  for my $n (@nodes)
    {
    # the net force on this node is the gravity
    $n->{_x_force} = $gx;
    $n->{_y_force} = $gy;
    if ($root == $n || defined $n->{origin})
      {
      # nodes that are relative to another are "pinned"
      $n->{_pinned} = undef;
      }
    else
      {
      $n->{x} = rand(100);
      $n->{y} = rand(100);
      push @particles, $n;
      }
    }

  my $energy = 1;
  while ($energy > 0.1)
    {
    $energy = 0;
    for my $n (@particles)
      {
      # reset forces on this node
      $n->{_x_force} = 0;
      $n->{_y_force} = 0;

      # Add forces of all other nodes. We need to include pinned nodes here,
      # too, since a moving node might get near a pinned one and get repelled.
      for my $n2 (@nodes)
        {
        next if $n2 == $n;			# don't repel yourself

	my $dx = ($n->{x} - $n2->{x});
	my $dy = ($n->{y} - $n2->{y});

	my $r = $dx * $dx + $dy * $dy;

	$r = 0.01 if $r < 0.01;			# too small? 
	if ($r < 4)
	  {
	  # not too big
	  $n->{_x_force} += 1 / $dx * $dx;
	  $n->{_y_force} += 1 / $dy * $dy;

	  my $dx2 = 1 / $dx * $dx;
	  my $dy2 = 1 / $dy * $dy;

	  print STDERR "# Force between $n->{name} and $n2->{name}: fx $dx2, fy $dy2\n";
	  }
        }

      # for all edges connected at this node
      for my $e (values %{$n->{edges}})
	{
	# exclude self-loops
	next if $e->{from} == $n && $e->{to} == $n;

	# get the other end-point of this edge
	my $n2 = $e->{from}; $n2 = $e->{to} if $n2 == $n;

	# XXX TODO
	# we should "connect" the edges to the appropriate port so that
	# they excert an off-center force

	my $dx = -($n->{x} - $n2->{x}) / 2;
	my $dy = -($n->{y} - $n2->{y}) / 2;

	print STDERR "# Spring force between $n->{name} and $n2->{name}: fx $dx, fy $dy\n";
	$n->{_x_force} += $dx; 
	$n->{_y_force} += $dy;
	}

      print STDERR "# $n->{name}: Summed force: fx $n->{_x_force}, fy $n->{_y_force}\n";

      # for grid-like layouts, add a small force drawing this node to the gridpoint
      # 0.7 => 1 - 0.7 => 0.3
      # 1.2 => 1 - 1.2 => -0.2

      my $dx = int($n->{x} + 0.5) - $n->{x};
      $n->{_x_force} += $dx;
      my $dy = int($n->{y} + 0.5) - $n->{y};
      $n->{_y_force} += $dy;

      print STDERR "# $n->{name}: Final force: fx $n->{_x_force}, fy $n->{_y_force}\n";

      $energy += $n->{_x_force} * $n->{_x_force} + $n->{_x_force} * $n->{_y_force}; 

      print STDERR "# Net energy: $energy\n";
      }

    # after having calculated all forces, move the nodes
    for my $n (@particles)
      {
      my $dx = $n->{_x_force};
      $dx = 5 if $dx > 5;		# limit it
      $n->{x} += $dx;

      my $dy = $n->{_y_force};
      $dy = 5 if $dy > 5;		# limit it
      $n->{y} += $dy;

      print STDERR "# $n->{name}: Position $n->{x}, $n->{y}\n";
      }

    sleep(1); print STDERR "\n";
    }

  for my $n (@nodes)
    {
    delete $n->{_x_force};
    delete $n->{_y_force};
    }
  $self;
  }

1;
__END__

=head1 NAME

Graph::Easy::Layout::Force - Force-based layouter for Graph::Easy

=head1 SYNOPSIS

	use Graph::Easy;
	
	my $graph = Graph::Easy->new();

	$graph->add_edge ('Bonn', 'Berlin');
	$graph->add_edge ('Bonn', 'Ulm');
	$graph->add_edge ('Ulm', 'Berlin');

	$graph->layout( type => 'force' );

	print $graph->as_ascii( );

	# prints:
	
	#   +------------------------+
	#   |                        v
	# +------+     +-----+     +--------+
	# | Bonn | --> | Ulm | --> | Berlin |
	# +------+     +-----+     +--------+

=head1 DESCRIPTION

C<Graph::Easy::Layout::Force> contains routines that calculate a
force-based layout for a graph.

Nodes repell each other, while edges connecting them draw them together.

The layouter calculates the forces on each node, then moves them around
according to these forces until things have settled down.

Used automatically by Graph::Easy.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 METHODS

This module injects the following methods into Graph::Easy:

=head2 _layout_force()

Calculates the node position with a force-based method.

=head1 AUTHOR

Copyright (C) 2004 - 2007 by Tels L<http://bloodgate.com>.

See the LICENSE file for information.

=cut
#############################################################################
# Grid-management and layout preperation.
#
# (c) by Tels 2004-2006.
#############################################################################

package Graph::Easy::Layout::Grid;

$VERSION = '0.07';

#############################################################################
#############################################################################

package Graph::Easy;

use strict;

sub _balance_sizes
  {
  # Given a list of column/row sizes and a minimum size that their sum must
  # be, will grow individual sizes until the constraint (sum) is met.
  my ($self, $sizes, $need) = @_;

  # XXX TODO: we can abort the loop and distribute the remaining nec. size
  # once all elements in $sizes are equal.

  return if $need < 1;

  # if there is only one element, return it immidiately
  if (@$sizes == 1)
    {
    $sizes->[0] = $need if $sizes->[0] < $need;
    return;
    }

  # endless loop until constraint is met
  while (1)
    {
  
    # find the smallest size, and also compute their sum
    my $sum = 0; my $i = 0;
    my $sm = $need + 1;		# start with an arbitrary size
    my $sm_i = 0;		# if none is != 0, then use the first
    for my $s (@$sizes)
      {
      $sum += $s;
      next if $s == 0;
      if ($s < $sm)
	{
        $sm = $s; $sm_i = $i; 
	}
      $i++;
      }

    # their sum is already equal or bigger than what we need?
    last if $sum >= $need;

    # increase the smallest size by one, then try again
    $sizes->[$sm_i]++;
    }
 
#  use Data::Dumper; print STDERR "# " . Dumper($sizes),"\n";

  undef;
  }

sub _prepare_layout
  {
  # this method is used by as_ascii() and as_svg() to find out the
  # sizes and placement of the different cells (edges, nodes etc).
  my ($self,$format) = @_;

  # Find out for each row and colum how big they are:
  #   +--------+-----+------+
  #   | Berlin | --> | Bonn | 
  #   +--------+-----+------+
  # results in:
  #        w,  h,  x,  y
  # 0,0 => 10, 3,  0,  0
  # 1,0 => 7,  3,  10, 0
  # 2,0 => 8,  3,  16, 0

  # Technically, we also need to "compress" away non-existant columns/rows.
  # We achive that by simply rendering them with size 0, so they become
  # practically invisible.

  my $cells = $self->{cells};
  my $rows = {};
  my $cols = {};

  # the last column/row (highest X,Y pair)
  my $mx = -1000000; my $my = -1000000;

  # We need to do this twice, once for single-cell objects, and again for
  # objects covering multiple cells. The single-cell objects can be solved
  # first:

  # find all x and y occurances to sort them by row/columns
  for my $cell (values %$cells)
    {
    my ($x,$y) = ($cell->{x}, $cell->{y});

    {
      no strict 'refs';

      my $method = '_correct_size_' . $format;
      $method = '_correct_size' unless $cell->can($method);
      $cell->$method();
    }

    my $w = $cell->{w} || 0;
    my $h = $cell->{h} || 0;

    # Set the minimum cell size only for single-celled objects:
    if ( (($cell->{cx}||1) + ($cell->{cy}||1)) == 2)
      { 
      # record maximum size for that col/row
      $rows->{$y} = $h if $h >= ($rows->{$y} || 0);
      $cols->{$x} = $w if $w >= ($cols->{$x} || 0);
      }

    # Find highest X,Y pair. Always use x,y, and not x+cx,y+cy, because
    # a multi-celled object "sticking" out will not count unless there
    # is another object in the same row/column.
    $mx = $x if $x > $mx;
    $my = $y if $y > $my;
    } 

  # insert a dummy row/column with size=0 as last
  $rows->{$my+1} = 0;
  $cols->{$mx+1} = 0;

  # do the last step again, but for multi-celled objects
  for my $cell (values %$cells)
    {
    my ($x,$y) = ($cell->{x}, $cell->{y});

    my $w = $cell->{w} || 0;
    my $h = $cell->{h} || 0;

    # Set the minimum cell size only for multi-celled objects:
    if ( (($cell->{cx} || 1) + ($cell->{cy}||1)) > 2)
      {
      $cell->{cx} ||= 1;
      $cell->{cy} ||= 1;

      # do this twice, for X and Y:

#      print STDERR "\n# ", $cell->{name} || $cell->{id}, " cx=$cell->{cx} cy=$cell->{cy} $cell->{w},$cell->{h}:\n";

      # create an array with the current sizes for the affacted rows/columns
      my @sizes;

#      print STDERR "# $cell->{cx} $cell->{cy} at cx:\n";

      # XXX TODO: no need to do this for empty/zero cols
      for (my $i = 0; $i < $cell->{cx}; $i++)
        {
        push @sizes, $cols->{$i+$x} || 0;
	}
      $self->_balance_sizes(\@sizes, $cell->{w});
      # store the result back
      for (my $i = 0; $i < $cell->{cx}; $i++)
        {
#        print STDERR "# store back $sizes[$i] to col ", $i+$x,"\n";
        $cols->{$i+$x} = $sizes[$i];
	}

      @sizes = ();

#      print STDERR "# $cell->{cx} $cell->{cy} at cy:\n";

      # XXX TODO: no need to do this for empty/zero cols
      for (my $i = 0; $i < $cell->{cy}; $i++)
        {
        push @sizes, $rows->{$i+$y} || 0;
	}
      $self->_balance_sizes(\@sizes, $cell->{h});
      # store the result back
      for (my $i = 0; $i < $cell->{cy}; $i++)
        {
#        print STDERR "# store back $sizes[$i] to row ", $i+$y,"\n";
        $rows->{$i+$y} = $sizes[$i];
	}
      }
    } 

  print STDERR "# Calculating absolute positions for rows/columns\n" if $self->{debug};

  # Now run through all rows/columns and get their absolute pos by taking all
  # previous ones into account.
  my $pos = 0;
  for my $y (sort { $a <=> $b } keys %$rows)
    {
    my $s = $rows->{$y};
    $rows->{$y} = $pos;			# first is 0, second is $rows[1] etc
    $pos += $s;
    }
  $pos = 0;
  for my $x (sort { $a <=> $b } keys %$cols)
    {
    my $s = $cols->{$x};
    $cols->{$x} = $pos;
    $pos += $s;
    }

  # find out max. dimensions for framebuffer
  print STDERR "# Finding max. dimensions for framebuffer\n" if $self->{debug};
  my $max_y = 0; my $max_x = 0;

  for my $v (values %$cells)
    {
    # Skip multi-celled nodes for later. 
    next if ($v->{cx}||1) + ($v->{cy}||1) != 2;

    # X and Y are col/row, so translate them to real pos
    my $x = $cols->{ $v->{x} };
    my $y = $rows->{ $v->{y} };

    # Also set correct the width/height of each cell to be the maximum
    # width/height of that row/column and store the previous size in 'minw'
    # and 'minh', respectively.

    $v->{minw} = $v->{w};
    $v->{minh} = $v->{h};

    # find next col/row
    my $nx = $v->{x} + 1;
    my $next_col = $cols->{ $nx };
    my $ny = $v->{y} + 1;
    my $next_row = $rows->{ $ny };

    $next_col = $cols->{ ++$nx } while (!defined $next_col);
    $next_row = $rows->{ ++$ny } while (!defined $next_row);

    $v->{w} = $next_col - $x;
    $v->{h} = $next_row - $y;

    my $m = $y + $v->{h} - 1;
    $max_y = $m if $m > $max_y;
    $m = $x + $v->{w} - 1;
    $max_x = $m if $m > $max_x;
    }

  # repeat the previous step, now for multi-celled objects
  foreach my $v (values %{$self->{cells}})
    {
    next unless defined $v->{x} && (($v->{cx}||1) + ($v->{cy}||1) > 2);

    # X and Y are col/row, so translate them to real pos
    my $x = $cols->{ $v->{x} };
    my $y = $rows->{ $v->{y} };

    $v->{minw} = $v->{w};
    $v->{minh} = $v->{h};

    # find next col/row
    my $nx = $v->{x} + ($v->{cx} || 1);
    my $next_col = $cols->{ $nx };
    my $ny = $v->{y} + ($v->{cy} || 1);
    my $next_row = $rows->{ $ny };

    $next_col = $cols->{ ++$nx } while (!defined $next_col);
    $next_row = $rows->{ ++$ny } while (!defined $next_row);

    $v->{w} = $next_col - $x;
    $v->{h} = $next_row - $y;

    my $m = $y + $v->{h} - 1;
    $max_y = $m if $m > $max_y;
    $m = $x + $v->{w} - 1;
    $max_x = $m if $m > $max_x;
    }

  # return what we found out:
  ($rows,$cols,$max_x,$max_y);
  }

1;
__END__

=head1 NAME

Graph::Easy::Layout::Grid - Grid management and size calculation

=head1 SYNOPSIS

	use Graph::Easy;
	
	my $graph = Graph::Easy->new();

	my $bonn = Graph::Easy::Node->new(
		name => 'Bonn',
	);
	my $berlin = Graph::Easy::Node->new(
		name => 'Berlin',
	);

	$graph->add_edge ($bonn, $berlin);

	$graph->layout();

	print $graph->as_ascii( );

	# prints:

	# +------+     +--------+
	# | Bonn | --> | Berlin |
	# +------+     +--------+

=head1 DESCRIPTION

C<Graph::Easy::Layout::Grid> contains routines that calculate cell sizes
on the grid, which is necessary for ASCII, boxart and SVG output.

Used automatically by Graph::Easy.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 METHODS

This module injects the following methods into Graph::Easy:

=head2 _prepare_layout()

  	my ($rows,$cols,$max_x,$max_y, \@V) = $graph->_prepare_layout();

Returns two hashes (C<$rows> and C<$cols>), containing the columns and rows
of the layout with their nec. sizes (in chars) plus the maximum
framebuffer size nec. for this layout. Also returns reference of
a list of all cells to be rendered.

=head1 AUTHOR

Copyright (C) 2004 - 2006 by Tels L<http://bloodgate.com>.

See the LICENSE file for information.

=cut
#############################################################################
# Path and cell management for Graph::Easy.
#
#############################################################################

package Graph::Easy::Layout::Path;

$VERSION = '0.16';

#############################################################################
#############################################################################

package Graph::Easy::Node;

use strict;

use Graph::Easy::Edge::Cell qw/
 EDGE_END_E EDGE_END_N EDGE_END_S EDGE_END_W
/;

sub _shuffle_dir
  {
  # take a list with four entries and shuffle them around according to $dir
  my ($self, $e, $dir) = @_;

  # $dir: 0 => north, 90 => east, 180 => south, 270 => west

  $dir = 90 unless defined $dir;		# default is east

  return [ @$e ] if $dir == 90;			# default is no shuffling

  my @shuffle = (0,1,2,3);			# the default
  @shuffle = (1,2,0,3) if $dir == 180;		# south
  @shuffle = (2,3,1,0) if $dir == 270;		# west
  @shuffle = (3,0,2,1) if $dir == 0;		# north

  [
    $e->[ $shuffle[0] ],
    $e->[ $shuffle[1] ],
    $e->[ $shuffle[2] ],
    $e->[ $shuffle[3] ],
  ];
  }

sub _shift
  {
  # get a flow shifted by X° to $dir
  my ($self, $turn) = @_;

  my $dir = $self->flow();

  $dir += $turn;
  $dir += 360 if $dir < 0;
  $dir -= 360 if $dir > 360;
  $dir;
  }

sub _near_places
  {
  # Take a node and return a list of possible placements around it and
  # prune out already occupied cells. $d is the distance from the node
  # border and defaults to two (for placements). Set it to one for
  # adjacent cells. 

  # If defined, $type contains four flags for each direction. If undef,
  # two entries (x,y) will be returned for each pos, instead of (x,y,type).

  # If $loose is true, no checking whether the returned fields are free
  # is done.

  my ($n, $cells, $d, $type, $loose, $dir) = @_;

  my $cx = $n->{cx} || 1;
  my $cy = $n->{cy} || 1;
  
  $d = 2 unless defined $d;		# default is distance = 2

  my $flags = $type;

  if (ref($flags) ne 'ARRAY')
    {
    $flags = [
      EDGE_END_W,
      EDGE_END_N,
      EDGE_END_E,
      EDGE_END_S,
     ];
    }
  $dir = $n->flow() unless defined $dir;

  my $index = $n->_shuffle_dir( [ 0,3,6,9], $dir);

  my @places = ();

  # single-celled node
  if ($cx + $cy == 2)
    {
    my @tries  = (
  	$n->{x} + $d, $n->{y}, $flags->[0],	# right
	$n->{x}, $n->{y} + $d, $flags->[1],	# down
	$n->{x} - $d, $n->{y}, $flags->[2],	# left
	$n->{x}, $n->{y} - $d, $flags->[3],	# up
      );

    for my $i (0..3)
      {
      my $idx = $index->[$i];
      my ($x,$y,$t) = ($tries[$idx], $tries[$idx+1], $tries[$idx+2]);

#      print STDERR "# Considering place $x, $y \n";

      # This quick check does not take node clusters or multi-celled nodes
      # into account. These are handled in $node->_do_place() later.
      next if !$loose && exists $cells->{"$x,$y"};
      push @places, $x, $y;
      push @places, $t if defined $type;
      }
    return @places;
    }

  # Handle a multi-celled node. For a 3x2 node:
  #      A   B   C
  #   J [00][10][20] D
  #   I [10][11][21] E
  #      H   G   F
  # we have 10 (3 * 2 + 2 * 2) places to consider

  my $nx = $n->{x};
  my $ny = $n->{y};
  my ($px,$py);

  my $idx = 0;
  my @results = ( [], [], [], [] );
 
  $cy--; $cx--;
  my $t = $flags->[$idx++];
  # right
  $px = $nx + $cx + $d;
  for my $y (0 .. $cy)
    {
    $py = $y + $ny;
    next if exists $cells->{"$px,$py"} && !$loose;
    push @{$results[0]}, $px, $py;
    push @{$results[0]}, $t if defined $type;
    }

  # below
  $py = $ny + $cy + $d;
  $t = $flags->[$idx++];
  for my $x (0 .. $cx)
    {
    $px = $x + $nx;
    next if exists $cells->{"$px,$py"} && !$loose;
    push @{$results[1]}, $px, $py;
    push @{$results[1]}, $t if defined $type;
    }

  # left
  $px = $nx - $d;
  $t = $flags->[$idx++];
  for my $y (0 .. $cy)
    {
    $py = $y + $ny;
    next if exists $cells->{"$px,$py"} && !$loose;
    push @{$results[2]}, $px, $py;
    push @{$results[2]}, $t if defined $type;
    }

  # top
  $py = $ny - $d;
  $t = $flags->[$idx];
  for my $x (0 .. $cx)
    {
    $px = $x + $nx;
    next if exists $cells->{"$px,$py"} && !$loose;
    push @{$results[3]}, $px, $py;
    push @{$results[3]}, $t if defined $type;
    }

  # accumulate the results in the requested, shuffled order
  for my $i (0..3)
    {
    my $idx = $index->[$i] / 3;
    push @places, @{$results[$idx]};
    }

  @places;
  }

sub _allowed_places
  {
  # given a list of potential positions, and a list of allowed positions,
  # return the valid ones (e.g. that are in both lists)
  my ($self, $places, $allowed, $step) = @_;

  print STDERR 
   "# calculating allowed places for $self->{name} from " . @$places . 
   " positions and " . scalar @$allowed . " allowed ones:\n"
    if $self->{graph}->{debug};

  $step ||= 2;				# default: "x,y"

  my @good;
  my $i = 0;
  while ($i < @$places)
    {
    my ($x,$y) = ($places->[$i], $places->[$i+1]);
    my $allow = 0;
    my $j = 0;
    while ($j < @$allowed)
      {
      my ($m,$n) = ($allowed->[$j], $allowed->[$j+1]);
      $allow++ and last if ($m == $x && $n == $y);
      } continue { $j += 2; }
    next unless $allow;
    push @good, $places->[$i + $_ -1] for (1..$step);
    } continue { $i += $step; }

  print STDERR "#  left with " . ((scalar @good) / $step) . " position(s)\n" if $self->{graph}->{debug};
  @good;
  }

sub _allow
  {
  # return a list of places, depending on the start/end atribute:
  # "south" - any place south
  # "south,0" - first place south
  # "south,-1" - last place south  
  # XXX TODO:
  # "south,0..2" - first three places south
  # "south,0,1,-1" - first, second and last place south  

  my ($self, $dir, @pos) = @_;

  # for relative direction, get the absolute flow from the node
  if ($dir =~ /^(front|forward|back|left|right)\z/)
    {
    # get the flow at the node
    $dir = $self->flow();
    }

  my $place = {
    'south' => [  0,0, 0,1, 'cx', 1,0 ],
    'north' => [ 0,-1, 0,0, 'cx', 1,0 ],
    'east' =>  [  0,0, 1,0, 'cy', 0,1 ],
    'west' =>  [ -1,0, 0,0, 'cy', 0,1 ] ,
    180 => [  0,0, 0,1, 'cx', 1,0 ],
    0 => [ 0,-1, 0,0, 'cx', 1,0 ],
    90 =>  [  0,0, 1,0, 'cy', 0,1 ],
    270 =>  [ -1,0, 0,0, 'cy', 0,1 ] ,
    };

  my $p = $place->{$dir};

  return [] unless defined $p;

  # start pos
  my $x = $p->[0] + $self->{x} + $p->[2] * $self->{cx};
  my $y = $p->[1] + $self->{y} + $p->[3] * $self->{cy};

  my @allowed;
  push @pos, '' if @pos == 0;

  my $c = $p->[4];
  if (@pos == 1 && $pos[0] eq '')
    {
    # allow all of them
    for (1 .. $self->{$c})
      {
      push @allowed, $x, $y;
      $x += $p->[5];
      $y += $p->[6];
      }
    } 
  else
    {
    # allow only the given position
    my $ps = $pos[0];
    # limit to 0..$self->{cx}-1
    $ps = $self->{$c} + $ps if $ps < 0;
    $ps = 0 if $ps < 0;
    $ps = $self->{$c} - 1 if $ps >= $self->{$c};
    $x += $p->[5] * $ps;
    $y += $p->[6] * $ps;
    push @allowed, $x, $y;
    }

  \@allowed;
  }

package Graph::Easy;
use strict;
use Graph::Easy::Node::Cell;

use Graph::Easy::Edge::Cell qw/
  EDGE_HOR EDGE_VER EDGE_CROSS
  EDGE_TYPE_MASK
  EDGE_HOLE
 /;

sub _clear_tries
  {
  # Take a list of potential positions for a node, and then remove the
  # ones that are immidiately near any other node.
  # Returns a list of "good" positions. Afterwards $node->{x} is undef.
  my ($self, $node, $cells, $tries) = @_;

  my $src = 0; my @new;

  print STDERR "# clearing ", scalar @$tries / 2, " tries for $node->{name}\n" if $self->{debug};

  my $node_grandpa = $node->find_grandparent();

  while ($src < scalar @$tries)
    {
    # check the current position

    # temporary place node here
    my $x = $tries->[$src];
    my $y = $tries->[$src+1];

#    print STDERR "# checking $x,$y\n" if $self->{debug};

    $node->{x} = $x;
    $node->{y} = $y;

    my @near = $node->_near_places($cells, 1, undef, 1);

    # push also the four corner cells to avoid placing nodes corner-to-corner
    push @near, $x-1, $y-1,					# upperleft corner
                $x-1, $y+($node->{cy}||1),			# lowerleft corner
                $x+($node->{cx}||1), $y+($node->{cy}||1),	# lowerright corner
                $x+($node->{cx}||1), $y-1;			# upperright corner
    
    # check all near places to be free from nodes (except our children)
    my $j = 0; my $g = 0;
    while ($j < @near)
      {
      my $xy = $near[$j]. ',' . $near[$j+1];

#      print STDERR "# checking near-place: $xy: " . ref($cells->{$xy}) . "\n" if $self->{debug};
      
      my $cell = $cells->{$xy};

      # skip, unless we are a children of node, or the cell is our children
      next unless ref($cell) && $cell->isa('Graph::Easy::Node');

      my $grandpa = $cell->find_grandparent();

      #       this cell is our children
      #                            this cell is our grandpa
      #                                                      has the same grandpa as node
      next if $grandpa == $node || $cell == $node_grandpa || $grandpa == $node_grandpa;

      $g++; last;

      } continue { $j += 2; }

    if ($g == 0)
      {
      push @new, $tries->[$src], $tries->[$src+1];
      }
    $src += 2;
    }

  $node->{x} = undef;

  @new;
  }

my $flow_shift = {
  270 => [ 0, -1 ],
   90 => [ 0,  1 ],
    0 => [ 1,  0 ],
  180 => [ -1, 0 ],
  };

sub _placed_shared
  {
  # check whether one of the nodes from the list of shared was already placed
  my ($self) = shift;

  my $placed;
  for my $n (@_)
    {
    $placed = [$n->{x}, $n->{y}] and last if defined $n->{x};
    }
  $placed;
  }

sub _find_node_place
  {
  # Try to place a node (or node cluster). Return score (usually 0).
  my ($self, $node, $try, $parent, $edge) = @_;

  $try ||= 0;

  print STDERR "# Finding place for $node->{name}, try #$try\n" if $self->{debug};
  print STDERR "# Parent node is '$parent->{name}'\n" if $self->{debug} && ref $parent;

  print STDERR "# called from ". join (" ", caller) . "\n" if $self->{debug};

  # If the node has a user-set rank, see if we already placed another node in that
  # row/column
  if ($node->{rank} >= 0)
    {
    my $r = abs($node->{rank});
#    print STDERR "# User-set rank for $node->{name} (rank $r)\n";
    my $c = $self->{_rank_coord};
#    use Data::Dumper; print STDERR "# rank_pos: \n", Dumper($self->{_rank_pos});
    if (exists $self->{_rank_pos}->{ $r })
      {
      my $co = { x => 0, y => 0 };
      $co->{$c} = $self->{_rank_pos}->{ $r };
      while (1 < 3)
        {
#	print STDERR "# trying to force placement of '$node->{name}' at $co->{x} $co->{y}\n";    
        return 0 if $node->_do_place($co->{x},$co->{y},$self);
        $co->{$c} += 2;
        }
      }
    }

  my $cells = $self->{cells};

#  local $self->{debug} = 1;

  my $min_dist = 2;
  # minlen = 0 => min_dist = 2,
  # minlen = 1 => min_dist = 2, 
  # minlen = 2 => min_dist = 3, etc
  $min_dist = $edge->attribute('minlen') + 1 if ref($edge);

  # if the node has outgoing edges (which might be shared)
  if (!ref($edge))
    {
    (undef,$edge) = each %{$node->{edges}} if keys %{$node->{edges}} > 0;
    }

  my $dir = undef; $dir = $edge->flow() if ref($edge);

  my @tries;
#  if (ref($parent) && defined $parent->{x})
  if (keys %{$node->{edges}} > 0)
    {
    my $src_node = $parent; $src_node = $edge->{from} if ref($edge) && !ref($parent);
    print STDERR "#  from $src_node->{name} to $node->{name}: edge $edge dir $dir\n" if $self->{debug};

    # if there are more than one edge to this node, and they share a start point,
    # move the node at least 3 cells away to create space for the joints

    my ($s_p, @ss_p);
    ($s_p, @ss_p) = $edge->port('start') if ref($edge);

    my ($from,$to);
    if (ref($edge))
      {
      $from = $edge->{from}; $to = $edge->{to};
      }

    my @shared_nodes;
    @shared_nodes = $from->nodes_sharing_start($s_p,@ss_p) if defined $s_p && @ss_p > 0;

    print STDERR "# Edge from '$src_node->{name}' shares an edge start with ", scalar @shared_nodes, " other nodes\n"
	if $self->{debug};

    if (@shared_nodes > 1)
      {
      $min_dist = 3 if $min_dist < 3;				# make space
      $min_dist++ if $edge->label() ne '';			# make more space for the label

      # if we are the first shared node to be placed
      my $placed = $self->_placed_shared(@shared_nodes);

      if (defined $placed)
        {
        # we are not the first, so skip the placement below
	# instead place on the same column/row as already placed node(s)
        my ($bx, $by) = @$placed;

	my $flow = $node->flow();

	print STDERR "# One of the shared nodes was already placed at ($bx,$by) with flow $flow\n"
	  if $self->{debug};

	my $ofs = 2;			# start with a distance of 2
	my ($mx, $my) = @{ ($flow_shift->{$flow} || [ 0, 1 ]) };

	while (1)
	  {
	  my $x = $bx + $mx * $ofs; my $y = $by + $my * $ofs;

	  print STDERR "# Trying to place $node->{name} at ($x,$y)\n"
	    if $self->{debug};

	  next if $self->_clear_tries($node, $cells, [ $x,$y ]) == 0;
	  last if $node->_do_place($x,$y,$self);
	  }
	continue {
	    $ofs += 2;
	  }
        return 0;			# found place already
	} # end we-are-the-first-to-be-placed
      }

    # shared end point?
    ($s_p, @ss_p) = $edge->port('end') if ref($edge);

    @shared_nodes = $to->nodes_sharing_end($s_p,@ss_p) if defined $s_p && @ss_p > 0;

    print STDERR "# Edge from '$src_node->{name}' shares an edge end with ", scalar @shared_nodes, " other nodes\n"
	if $self->{debug};

    if (@shared_nodes > 1)
      {
      $min_dist = 3 if $min_dist < 3;
      $min_dist++ if $edge->label() ne '';			# make more space for the label

      # if the node to be placed is not in the list to be placed, it is the end-point
      
      # see if we are the first shared node to be placed
      my $placed = $self->_placed_shared(@shared_nodes);

#      print STDERR "# "; for (@shared_nodes) { print $_->{name}, " "; } print "\n";

      if ((grep( $_ == $node, @shared_nodes)) && defined $placed)
	{
        # we are not the first, so skip the placement below
	# instead place on the same column/row as already placed node(s)
        my ($bx, $by) = @$placed;

	my $flow = $node->flow();

	print STDERR "# One of the shared nodes was already placed at ($bx,$by) with flow $flow\n"
	  if $self->{debug};

	my $ofs = 2;			# start with a distance of 2
	my ($mx, $my) = @{ ($flow_shift->{$flow} || [ 0, 1 ]) };

	while (1)
	  {
	  my $x = $bx + $mx * $ofs; my $y = $by + $my * $ofs;

	  print STDERR "# Trying to place $node->{name} at ($x,$y)\n"
	    if $self->{debug};

	  next if $self->_clear_tries($node, $cells, [ $x,$y ]) == 0;
	  last if $node->_do_place($x,$y,$self);
	  }
	continue {
	    $ofs += 2;
	  }
        return 0;			# found place already
	} # end we-are-the-first-to-be-placed
      }
    }

  if (ref($parent) && defined $parent->{x})
    {
    @tries = $parent->_near_places($cells, $min_dist, undef, 0, $dir);

    print STDERR 
	"# Trying chained placement of $node->{name} with min distance $min_dist from parent $parent->{name}\n"
	if $self->{debug};

    # weed out positions that are unsuitable
    @tries = $self->_clear_tries($node, $cells, \@tries);

    splice (@tries,0,$try) if $try > 0;	# remove the first N tries
    print STDERR "# Left with " . scalar @tries . " tries for node $node->{name}\n" if $self->{debug};

    while (@tries > 0)
      {
      my $x = shift @tries;
      my $y = shift @tries;

      print STDERR "# Trying to place $node->{name} at $x,$y\n" if $self->{debug};
      return 0 if $node->_do_place($x,$y,$self);
      } # for all trial positions
    }

  print STDERR "# Trying to place $node->{name} at 0,0\n" if $try == 0 && $self->{debug};
  # Try to place node at upper left corner (the very first node to be
  # placed will usually end up there).
  return 0 if $try == 0 && $node->_do_place(0,0,$self);

  # try to place node near the predecessor(s)
  my @pre_all = $node->predecessors();

  print STDERR "# Predecessors of $node->{name} " . scalar @pre_all . "\n" if $self->{debug};

  # find all already placed predecessors
  my @pre;
  for my $p (@pre_all)
    {
    push @pre, $p if defined $p->{x};
    print STDERR "# Placed predecessors of $node->{name}: $p->{name} at $p->{x},$p->{y}\n" if $self->{debug} && defined $p->{x};
    }

  # sort predecessors on their rank (to try first the higher ranking ones on placement)
  @pre = sort { $b->{rank} <=> $a->{rank} } @pre;

  print STDERR "# Number of placed predecessors of $node->{name}: " . scalar @pre . "\n" if $self->{debug};

  if (@pre <= 2 && @pre > 0)
    {

    if (@pre == 1)
      {
      # only one placed predecessor, so place $node near it
      print STDERR "# placing $node->{name} near predecessor\n" if $self->{debug};
      @tries = ( $pre[0]->_near_places($cells, $min_dist), $pre[0]->_near_places($cells,$min_dist+2) ); 
      }
    else
      {
      # two placed predecessors, so place at crossing point of both of them
      # compute difference between the two nodes

      my $dx = ($pre[0]->{x} - $pre[1]->{x});
      my $dy = ($pre[0]->{y} - $pre[1]->{y});

      # are both nodes NOT on a straight line?
      if ($dx != 0 && $dy != 0)
        {
        # ok, so try to place at the crossing point
	@tries = ( 
	  $pre[0]->{x}, $pre[1]->{y},
	  $pre[0]->{y}, $pre[1]->{x},
	);
        }
      else
        {
        # two nodes on a line, try to place node in the middle
        if ($dx == 0)
          {
	  @tries = ( $pre[1]->{x}, $pre[1]->{y} + int($dy / 2) );
          }
        else
          {
	  @tries = ( $pre[1]->{x} + int($dx / 2), $pre[1]->{y} );
          }
        }
      # XXX TODO BUG: shouldnt we also try this if we have more than 2 placed
      # predecessors?

      # In addition, we can also try to place the node around the
      # different nodes:
      foreach my $n (@pre)
        {
        push @tries, $n->_near_places($cells, $min_dist);
        }
      }
    }

  my @suc_all = $node->successors();

  # find all already placed successors
  my @suc;
  for my $s (@suc_all)
    {
    push @suc, $s if defined $s->{x};
    }
  print STDERR "# Number of placed successors of $node->{name}: " . scalar @suc . "\n" if $self->{debug};
  foreach my $s (@suc)
    {
    # for each successors (especially if there is only one), try to place near
    push @tries, $s->_near_places($cells, $min_dist); 
    push @tries, $s->_near_places($cells, $min_dist + 2);
    }

  # weed out positions that are unsuitable
  @tries = $self->_clear_tries($node, $cells, \@tries);

  print STDERR "# Left with " . scalar @tries . " for node $node->{name}\n" if $self->{debug};

  splice (@tries,0,$try) if $try > 0;	# remove the first N tries
  
  while (@tries > 0)
    {
    my $x = shift @tries;
    my $y = shift @tries;

    print STDERR "# Trying to place $node->{name} at $x,$y\n" if $self->{debug};
    return 0 if $node->_do_place($x,$y,$self);

    } # for all trial positions

  ##############################################################################
  # all simple possibilities exhausted, try a generic approach

  print STDERR "# No more simple possibilities for node $node->{name}\n" if $self->{debug};

  # XXX TODO:
  # find out which sides of the node predecessor node(s) still have free
  # ports/slots. With increasing distances, try to place the node around these.

  # If no predecessors/incoming edges, try to place in column 0, otherwise 
  # considered the node's rank, too

  my $col = 0; $col = $node->{rank} * 2 if @pre > 0;

  $col = $pre[0]->{x} if @pre > 0;
  
  # find the first free row
  my $y = 0;
  $y +=2 while (exists $cells->{"$col,$y"});
  $y += 1 if exists $cells->{"$col," . ($y-1)};		# leave one cell spacing

  # now try to place node (or node cluster)
  while (1)
    {
    next if $self->_clear_tries($node, $cells, [ $col,$y ]) == 0;
    last if $node->_do_place($col,$y,$self);
    }
    continue {
    $y += 2;
    }

  $node->{x} = $col; 

  0;							# success, score 0 
  }

sub _trace_path
  {
  # find a free way from $src to $dst (both need to be placed beforehand)
  my ($self, $src, $dst, $edge) = @_;

  print STDERR "# Finding path from '$src->{name}' to '$dst->{name}'\n" if $self->{debug};
  print STDERR "# src: $src->{x}, $src->{y} dst: $dst->{x}, $dst->{y}\n" if $self->{debug};

  my $coords = $self->_find_path ($src, $dst, $edge);

  # found no path?
  if (!defined $coords)
    {
    print STDERR "# Unable to find path from $src->{name} ($src->{x},$src->{y}) to $dst->{name} ($dst->{x},$dst->{y})\n" if $self->{debug};
    return undef;
    }

  # path is empty, happens for sharing edges with only a joint
  return 1 if scalar @$coords == 0;

  # Create all cells from the returned list and score path (lower score: better)
  my $i = 0;
  my $score = 0;
  while ($i < scalar @$coords)
    {
    my $type = $coords->[$i+2];
    $self->_create_cell($edge,$coords->[$i],$coords->[$i+1],$type);
    $score ++;					# each element: one point
    $type &= EDGE_TYPE_MASK;			# mask flags
    # edge bend or cross: one point extra
    $score ++ if $type != EDGE_HOR && $type != EDGE_VER;
    $score += 3 if $type == EDGE_CROSS;		# crossings are doubleplusungood
    $i += 3;
    }

  $score;
  }

sub _create_cell
  {
  my ($self,$edge,$x,$y,$type) = @_;

  my $cells = $self->{cells}; my $xy = "$x,$y";
  
  if (ref($cells->{$xy}) && $cells->{$xy}->isa('Graph::Easy::Edge'))
    {
    $cells->{$xy}->_make_cross($edge,$type & EDGE_FLAG_MASK);
    # insert a EDGE_HOLE into the cells of the edge (but not into the list of
    # to-be-rendered cells). This cell will be removed by the optimizer later on.
    Graph::Easy::Edge::Cell->new( type => EDGE_HOLE, edge => $edge, x => $x, y => $y );
    return;
    }

  my $path = Graph::Easy::Edge::Cell->new( type => $type, edge => $edge, x => $x, y => $y );
  $cells->{$xy} = $path;	# store in cells
  }

sub _path_is_clear
  {
  # For all points (x,y pairs) in the path, check that the cell is still free
  # $path points to a list of [ x,y,type, x,y,type, ...]
  my ($self,$path) = @_;

  my $cells = $self->{cells};
  my $i = 0;
  while ($i < scalar @$path)
    {
    my $x = $path->[$i];
    my $y = $path->[$i+1];
    # my $t = $path->[$i+2];
    $i += 3;

    return 0 if exists $cells->{"$x,$y"};	# obstacle hit
    } 
  1;						# path is clear
  }

1;
__END__

=head1 NAME

Graph::Easy::Layout::Path - Path management for Manhattan-style grids

=head1 SYNOPSIS

	use Graph::Easy;
	
	my $graph = Graph::Easy->new();

	my $bonn = Graph::Easy::Node->new(
		name => 'Bonn',
	);
	my $berlin = Graph::Easy::Node->new(
		name => 'Berlin',
	);

	$graph->add_edge ($bonn, $berlin);

	$graph->layout();

	print $graph->as_ascii( );

	# prints:

	# +------+     +--------+
	# | Bonn | --> | Berlin |
	# +------+     +--------+

=head1 DESCRIPTION

C<Graph::Easy::Layout::Scout> contains just the actual path-managing code for
L<Graph::Easy|Graph::Easy>, e.g. to create/destroy/maintain paths, node
placement etc.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 METHODS into Graph::Easy

This module injects the following methods into C<Graph::Easy>:

=head2 _path_is_clear()

	$graph->_path_is_clear($path);

For all points (x,y pairs) in the path, check that the cell is still free.
C<$path> points to a list x,y,type pairs as in C<< [ [x,y,type], [x,y,type], ...] >>.

=head2 _create_cell()

	my $cell = $graph->($edge,$x,$y,$type);

Create a cell at C<$x,$y> coordinates with type C<$type> for the specified
edge.

=head2 _path_is_clear()

	$graph->_path_is_clear();

For all points (x,y pairs) in the path, check that the cell is still free.
C<$path> points to a list of C<[ x,y,type, x,y,type, ...]>.

Returns true when the path is clear, false otherwise.

=head2 _trace_path()

	my $path = my $graph->_trace_path($src,$dst,$edge);

Find a free way from source node/group to destination node/group for the
specified edge. Both source and destination need to be placed beforehand.

=head1 METHODS in Graph::Easy::Node

This module injects the following methods into C<Graph::Easy::Node>:

=head2 _near_places()

	my $node->_near_places();
  
Take a node and return a list of possible placements around it and
prune out already occupied cells. $d is the distance from the node
border and defaults to two (for placements). Set it to one for
adjacent cells. 

=head2 _shuffle_dir()

	my $dirs = $node->_shuffle_dir( [ 0,1,2,3 ], $dir);

Take a ref to an array with four entries and shuffle them around according to
C<$dir>.

=head2 _shift()

	my $dir = $node->_shift($degrees);

Return a the C<flow()> direction shifted by X degrees to C<$dir>.

=head1 AUTHOR

Copyright (C) 2004 - 2007 by Tels L<http://bloodgate.com>.

See the LICENSE file for information.

=cut
#############################################################################
# Layout directed graphs on a flat plane. Part of Graph::Easy.
#
# Code to repair spliced layouts (after group cells have been inserted).
#
#############################################################################

package Graph::Easy::Layout::Repair;

$VERSION = '0.08';

#############################################################################
#############################################################################
# for layouts with groups:

package Graph::Easy;

use strict;

sub _edges_into_groups
  {
  my $self = shift;

  # Put all edges between two nodes with the same group in the group as well
  for my $edge (values %{$self->{edges}})
    {
    my $gf = $edge->{from}->group();
    my $gt = $edge->{to}->group();

    $gf->_add_edge($edge) if defined $gf && defined $gt && $gf == $gt;
    }

  $self;
  }

sub _repair_nodes
  {
  # Splicing the rows/columns to add filler cells will have torn holes into
  # multi-edges nodes, so we insert additional filler cells.
  my ($self) = @_;
  my $cells = $self->{cells};

  # Make multi-celled nodes occupy the proper double space due to splicing
  # in group cell has doubled the layout in each direction:
  for my $n ($self->nodes())
    {
    # 1 => 1, 2 => 3, 3 => 5, 4 => 7 etc
    $n->{cx} = $n->{cx} * 2 - 1;
    $n->{cy} = $n->{cy} * 2 - 1;
    }

  # We might get away with not inserting filler cells if we just mark the
  # cells as used (e.g. use only one global filler cell) since filler cells
  # aren't actually rendered, anyway.

  for my $cell (values %$cells)
    {
    next unless $cell->isa('Graph::Easy::Node::Cell');

    # we have "[ empty  ] [ filler ]" (unless cell is on the same column as node)
    if ($cell->{x} > $cell->{node}->{x})
      {
      my $x = $cell->{x} - 1; my $y = $cell->{y}; 

#      print STDERR "# inserting filler at $x,$y for $cell->{node}->{name}\n";
      $cells->{"$x,$y"} = 
        Graph::Easy::Node::Cell->new(node => $cell->{node}, x => $x, y => $y );
      }

    # we have " [ empty ]  "
    #         " [ filler ] " (unless cell is on the same row as node)
    if ($cell->{y} > $cell->{node}->{y})
      {
      my $x = $cell->{x}; my $y = $cell->{y} - 1;

#      print STDERR "# inserting filler at $x,$y for $cell->{node}->{name}\n";
      $cells->{"$x,$y"} = 
        Graph::Easy::Node::Cell->new(node => $cell->{node}, x => $x, y => $y );
      }
    }
  }

sub _repair_cell
  {
  my ($self, $type, $edge, $x, $y, $after, $before) = @_;

  # already repaired?
  return if exists $self->{cells}->{"$x,$y"};

#  print STDERR "# Insert edge cell at $x,$y (type $type) for edge $edge->{from}->{name} --> $edge->{to}->{name}\n";

  $self->{cells}->{"$x,$y"} =
    Graph::Easy::Edge::Cell->new( 
      type => $type, 
      edge => $edge, x => $x, y => $y, before => $before, after => $after );

  }

sub _splice_edges
  {
  # Splicing the rows/columns to add filler cells might have torn holes into
  # edges, so we splice these together again.
  my ($self) = @_;

  my $cells = $self->{cells};

  print STDERR "# Reparing spliced layout\n" if $self->{debug};

  # Edge end/start points inside groups are not handled here, but in
  # _repair_group_edge()

  # go over the old layout, because the new cells were inserted into odd
  # rows/columns and we do not care for these:
  for my $cell (sort { $a->{x} <=> $b->{x} || $a->{y} <=> $b->{y} } values %$cells)
    {
    next unless $cell->isa('Graph::Easy::Edge::Cell');
 
    my $edge = $cell->{edge}; 

    #########################################################################
    # check for "[ JOINT ] [ empty  ] [ edge ]"
    
    my $x = $cell->{x} + 2; my $y = $cell->{y}; 

    my $type = $cell->{type} & EDGE_TYPE_MASK;

    # left is a joint and right exists
    if ( ($type == EDGE_S_E_W || $type == EDGE_N_E_W || $type == EDGE_E_N_S)
         && exists $cells->{"$x,$y"})
      {
      my $right = $cells->{"$x,$y"};

#      print STDERR "# at $x,$y\n";

      # |-> [ empty ] [ node ]
      if ($right->isa('Graph::Easy::Edge::Cell'))
	{
        # when the left one is a joint, the right one must be an edge
        $self->error("Found non-edge piece ($right->{type} $right) right to a joint ($type)") 
          unless $right->isa('Graph::Easy::Edge::Cell');

#        print STDERR "splicing in HOR piece to the right of joint at $x, $y ($edge $right $right->{edge})\n";

        # insert the new piece before the first part of the edge after the joint
        $self->_repair_cell(EDGE_HOR(), $right->{edge},$cell->{x}+1,$y,0)
          if $edge != $right->{edge};
        }
      }

    #########################################################################
    # check for "[ edge ] [ empty  ] [ joint ]"
    
    $x = $cell->{x} - 2; $y = $cell->{y}; 

    # right is a joint and left exists
    if ( ($type == EDGE_S_E_W || $type == EDGE_N_E_W || $type == EDGE_W_N_S)
         && exists $cells->{"$x,$y"})
     {
      my $left = $cells->{"$x,$y"};

      # [ node ] [ empty ] [ <-| ]
      if (!$left->isa('Graph::Easy::Node'))
	{
        # when the left one is a joint, the right one must be an edge
        $self->error('Found non-edge piece right to a joint') 
          unless $left->isa('Graph::Easy::Edge::Cell');

        # insert the new piece before the joint
        $self->_repair_cell(EDGE_HOR(), $edge, $cell->{x}+1,$y,0) # $left,$cell)
          if $edge != $left->{edge};
	}
      }

    #########################################################################
    # check for " [ joint ]
    #		  [ empty ]
    #             [ edge ]"
    
    $x = $cell->{x}; $y = $cell->{y} + 2; 

    # top is a joint and down exists
    if ( ($type == EDGE_S_E_W || $type == EDGE_E_N_S || $type == EDGE_W_N_S)
         && exists $cells->{"$x,$y"})
     {
      my $bottom = $cells->{"$x,$y"};

      # when top is a joint, the bottom one must be an edge
      $self->error('Found non-edge piece below a joint') 
        unless $bottom->isa('Graph::Easy::Edge::Cell');

#      print STDERR "splicing in VER piece below joint at $x, $y\n";

	# XXX TODO
      # insert the new piece after the joint
      $self->_repair_cell(EDGE_VER(), $bottom->{edge},$x,$cell->{y}+1,0)
        if $edge != $bottom->{edge}; 
      }

    #########################################################################
    # check for "[ --- ] [ empty  ] [ ---> ]"

    $x = $cell->{x} + 2; $y = $cell->{y}; 

    if (exists $cells->{"$x,$y"})
      {
      my $right = $cells->{"$x,$y"};

      $self->_repair_cell(EDGE_HOR(), $edge, $cell->{x}+1,$y,$cell,$right)
        if $right->isa('Graph::Easy::Edge::Cell') && 
           defined $right->{edge} && defined $right->{type} &&
	# check that both cells belong to the same edge
	(  $edge == $right->{edge}  ||
	# or the right part is a cross
	   $right->{type} == EDGE_CROSS ||
	# or the left part is a cross
	   $cell->{type} == EDGE_CROSS );
      }
    
    #########################################################################
    # check for [ | ]
    #		[ empty ]
    #		[ | ]
    $x = $cell->{x}; $y = $cell->{y}+2; 

    if (exists $cells->{"$x,$y"})
      {
      my $below = $cells->{"$x,$y"};

      $self->_repair_cell(EDGE_VER(),$edge,$x,$cell->{y}+1,$cell,$below)
	if $below->isa('Graph::Easy::Edge::Cell') &&
        # check that both cells belong to the same edge
	(  $edge == $below->{edge}  ||
	# or the lower part is a cross
	   $below->{type} == EDGE_CROSS ||
	# or the upper part is a cross
	   $cell->{type} == EDGE_CROSS );
      }

    } # end for all cells

  $self;
  }

sub _new_edge_cell
  {
  # create a new edge cell to be spliced into the layout for repairs
  my ($self, $cells, $group, $edge, $x, $y, $after, $type) = @_;

  $type += EDGE_SHORT_CELL() if defined $group;

  my $e_cell = Graph::Easy::Edge::Cell->new( 
	  type => $type, edge => $edge, x => $x, y => $y, after => $after);
  $group->_del_cell($e_cell) if defined $group;
  $cells->{"$x,$y"} = $e_cell;
  }

sub _check_edge_cell
  {
  # check a start/end edge cell and if nec. repair it
  my ($self, $cell, $x, $y, $flag, $type, $match, $check, $where) = @_;

  my $edge = $cell->{edge};
  if (grep { exists $_->{cell_class} && $_->{cell_class} =~ $match } values %$check)
    {
    $cell->{type} &= ~ $flag;		# delete the flag

    $self->_new_edge_cell(
	$self->{cells}, $edge->{group}, $edge, $x, $y, $where, $type + $flag);
    }
  }

sub _repair_group_edge
  {
  # repair an edges inside a group
  my ($self, $cell, $rows, $cols, $group) = @_;

  my $cells = $self->{cells};
  my ($x,$y,$doit);

  my $type = $cell->{type};

  #########################################################################
  # check for " [ empty ] [ |---> ]"
  $x = $cell->{x} - 1; $y = $cell->{y};

  $self->_check_edge_cell($cell, $x, $y, EDGE_START_W, EDGE_HOR, qr/g[rl]/, $cols->{$x}, 0)
    if (($type & EDGE_START_MASK) == EDGE_START_W);

  #########################################################################
  # check for " [ <--- ] [ empty ]"
  $x = $cell->{x} + 1;

  $self->_check_edge_cell($cell, $x, $y, EDGE_START_E, EDGE_HOR, qr/g[rl]/, $cols->{$x}, 0)
    if (($type & EDGE_START_MASK) == EDGE_START_E);

  #########################################################################
  # check for " [ --> ] [ empty ]"
  $x = $cell->{x} + 1;

  $self->_check_edge_cell($cell, $x, $y, EDGE_END_E, EDGE_HOR, qr/g[rl]/, $cols->{$x}, -1)
    if (($type & EDGE_END_MASK) == EDGE_END_E);

#  $self->_check_edge_cell($cell, $x, $y, EDGE_END_E, EDGE_E_N_S, qr/g[rl]/, $cols->{$x}, -1)
#    if (($type & EDGE_END_MASK) == EDGE_END_E);

  #########################################################################
  # check for " [ empty ] [ <-- ]"
  $x = $cell->{x} - 1;

  $self->_check_edge_cell($cell, $x, $y, EDGE_END_W, EDGE_HOR, qr/g[rl]/, $cols->{$x}, -1)
    if (($type & EDGE_END_MASK) == EDGE_END_W);

  #########################################################################
  #########################################################################
  # vertical cases

  #########################################################################
  # check for [empty] 
  #           [ | ]
  $x = $cell->{x}; $y = $cell->{y} - 1;

  $self->_check_edge_cell($cell, $x, $y, EDGE_START_N, EDGE_VER, qr/g[tb]/, $rows->{$y}, 0)
    if (($type & EDGE_START_MASK) == EDGE_START_N);

  #########################################################################
  # check for [ |] 
  #           [ empty ]
  $y = $cell->{y} + 1;

  $self->_check_edge_cell($cell, $x, $y, EDGE_START_S, EDGE_VER, qr/g[tb]/, $rows->{$y}, 0)
    if (($type & EDGE_START_MASK) == EDGE_START_S);

  #########################################################################
  # check for [ v ]
  #           [empty] 
  $y = $cell->{y} + 1;

  $self->_check_edge_cell($cell, $x, $y, EDGE_END_S, EDGE_VER, qr/g[tb]/, $rows->{$y}, -1)
    if (($type & EDGE_END_MASK) == EDGE_END_S);

  #########################################################################
  # check for [ empty ]
  #           [ ^     ] 
  $y = $cell->{y} - 1;

  $self->_check_edge_cell($cell, $x, $y, EDGE_END_N, EDGE_VER, qr/g[tb]/, $rows->{$y}, -1)
    if (($type & EDGE_END_MASK) == EDGE_END_N);
  }

sub _repair_edge
  {
  # repair an edge outside a group
  my ($self, $cell, $rows, $cols) = @_;

  my $cells = $self->{cells};

  #########################################################################
  # check for [ |\n|\nv ]
  #	        [empty]	... [non-empty]
  #	        [node]

  my $x = $cell->{x}; my $y = $cell->{y} + 1;

  my $below = $cells->{"$x,$y"}; 		# must be empty

  if  (!ref($below) && (($cell->{type} & EDGE_END_MASK) == EDGE_END_S))
    {
    if (grep { exists $_->{cell_class} && $_->{cell_class} =~ /g[tb]/ } values %{$rows->{$y}})
      {
      # delete the start flag
      $cell->{type} &= ~ EDGE_END_S;

      $self->_new_edge_cell($cells, undef, $cell->{edge}, $x, $y, -1, 
          EDGE_VER() + EDGE_END_S() );
      }
    }
  # XXX TODO: do the other ends (END_N, END_W, END_E), too

  }

sub _repair_edges
  {
  # fix edge end/start cells to be closer to the node cell they point at
  my ($self, $rows, $cols) = @_;

  my $cells = $self->{cells};

  # go over all existing cells
  for my $cell (sort { $a->{x} <=> $b->{x} || $a->{y} <=> $b->{y} } values %$cells)
    {
    next unless $cell->isa('Graph::Easy::Edge::Cell');

    # skip odd positions
    next unless ($cell->{x} & 1) == 0 && ($cell->{y} & 1) == 0; 

    my $group = $cell->group();

    $self->_repair_edge($cell,$rows,$cols) unless $group;
    $self->_repair_group_edge($cell,$rows,$cols,$group) if $group;

    } # end for all cells
  }

sub _fill_group_cells
  {
  # after doing a layout(), we need to add the group to each cell based on
  # what group the nearest node is in.
  my ($self, $cells_layout) = @_;

  print STDERR "\n# Padding with fill cells, have ", 
    scalar $self->groups(), " groups.\n" if $self->{debug};

  # take a shortcut if we do not have groups
  return $self if $self->groups == 0;

  $self->{padding_cells} = 1;		# set to true

  # We need to insert "filler" cells around each node/edge/cell:

  # To "insert" the filler cells, we simple multiply each X and Y by 2, this
  # is O(N) where N is the number of actually existing cells. Otherwise we
  # would have to create the full table-layout, and then insert rows/columns.
  my $cells = {};
  for my $key (keys %$cells_layout)
    {
    my ($x,$y) = split /,/, $key;
    my $cell = $cells_layout->{$key};

    $x *= 2;
    $y *= 2;
    $cell->{x} = $x;
    $cell->{y} = $y;

    $cells->{"$x,$y"} = $cell; 
    }

  $self->{cells} = $cells;		# override with new cell layout

  $self->_splice_edges();		# repair edges
  $self->_repair_nodes();		# repair multi-celled nodes

  my $c = 'Graph::Easy::Group::Cell';
  for my $cell (values %{$self->{cells}})
    {
    # DO NOT MODIFY $cell IN THE LOOP BODY!

    my ($x,$y) = ($cell->{x},$cell->{y});

    # find the primary node for node cells, for group check
    my $group = $cell->group();

    # not part of group, so no group-cells nec.
    next unless $group;

    # now insert up to 8 filler cells around this cell
    my $ofs = [ -1, 0,
		0, -1,
		+1, 0,
		+1, 0,
		0, +1,
		0, +1,
		-1, 0,
		-1, 0,  ];
    while (@$ofs > 0)
      {
      $x += shift @$ofs;
      $y += shift @$ofs;

      $cells->{"$x,$y"} = $c->new ( graph => $self, group => $group, x => $x, y => $y )
        unless exists $cells->{"$x,$y"};
      }
    }

  # Nodes positioned two cols/rows apart (f.i. y == 0 and y == 2) will be
  # three cells apart (y == 0 and y == 4) after the splicing, the step above
  # will not be able to close that hole - it will create fillers at y == 1 and
  # y == 3. So we close these holes now with an extra step.
  for my $cell (values %{$self->{cells}})
    {
    # only for filler cells
    next unless $cell->isa('Graph::Easy::Group::Cell');

    my ($sx,$sy) = ($cell->{x},$cell->{y});
    my $group = $cell->{group};

    my $x = $sx; my $y2 = $sy + 2; my $y = $sy + 1;
    # look for:
    # [ group ]
    # [ empty ]
    # [ group ]
    if (exists $cells->{"$x,$y2"} && !exists $cells->{"$x,$y"})
      {
      my $down = $cells->{"$x,$y2"};
      if ($down->isa('Graph::Easy::Group::Cell') && $down->{group} == $group)
        {
	$cells->{"$x,$y"} = $c->new ( graph => $self, group => $group, x => $x, y => $y );
        }
      }
    $x = $sx+1; my $x2 = $sx + 2; $y = $sy;
    # look for:
    # [ group ]  [ empty ]  [ group ]
    if (exists $cells->{"$x2,$y"} && !exists $cells->{"$x,$y"})
      {
      my $right = $cells->{"$x2,$y"};
      if ($right->isa('Graph::Easy::Group::Cell') && $right->{group} == $group)
        {
	$cells->{"$x,$y"} = $c->new ( graph => $self, group => $group, x => $x, y => $y );
        }
      }
    }

  # XXX TODO
  # we should "grow" the group area to close holes

  for my $group (values %{$self->{groups}})
    {
    $group->_set_cell_types($cells);
    }

  # create a mapping for each row/column so that we can repair edge starts/ends
  my $rows = {};
  my $cols = {};
  for my $cell (values %$cells)
    {
    $rows->{$cell->{y}}->{$cell->{x}} = $cell;
    $cols->{$cell->{x}}->{$cell->{y}} = $cell;
    }
  $self->_repair_edges($rows,$cols);	# insert short edge cells on group
					# border rows/columns

  # for all groups, set the cell carrying the label (top-left-most cell)
  for my $group (values %{$self->{groups}})
    {
    $group->_find_label_cell();
    }

# DEBUG:
# for my $cell (values %$cells)
#   { 
#   $cell->_correct_size();
#   }
#
# my $y = 0;
# for my $cell (sort { $a->{y} <=> $b->{y} || $a->{x} <=> $b->{x} } values %$cells)
#   {
#  print STDERR "\n" if $y != $cell->{y};
#  print STDERR "$cell->{x},$cell->{y}, $cell->{w},$cell->{h}, ", $cell->{group}->{name} || 'none', "\t";
#   $y = $cell->{y};
#  }
# print STDERR "\n";

  $self;
  }

1;
__END__

=head1 NAME

Graph::Easy::Layout::Repair - Repair spliced layout with group cells

=head1 SYNOPSIS

	use Graph::Easy;
	
	my $graph = Graph::Easy->new();

	my $bonn = Graph::Easy::Node->new(
		name => 'Bonn',
	);
	my $berlin = Graph::Easy::Node->new(
		name => 'Berlin',
	);

	$graph->add_edge ($bonn, $berlin);

	$graph->layout();

	print $graph->as_ascii( );

	# prints:

	# +------+     +--------+
	# | Bonn | --> | Berlin |
	# +------+     +--------+

=head1 DESCRIPTION

C<Graph::Easy::Layout::Repair> contains code that can splice in
group cells into a layout, as well as repair the layout after that step.

It is part of L<Graph::Easy|Graph::Easy> and used automatically.

=head1 METHODS

C<Graph::Easy::Layout> injects the following methods into the C<Graph::Easy>
namespace:

=head2 _edges_into_groups()

Put the edges into the appropriate group and class.

=head2 _assign_ranks()

	$graph->_assign_ranks();

=head2 _repair_nodes()

Splicing the rows/columns to add filler cells will have torn holes into
multi-edges nodes, so we insert additional filler cells to repair this.

=head2 _splice_edges()

Splicing the rows/columns to add filler cells might have torn holes into
multi-celled edges, so we splice these together again.

=head2 _repair_edges()

Splicing the rows/columns to add filler cells might have put "holes"
between an edge start/end and the node cell it points to. This
routine fixes this problem by extending the edge by one cell if
necessary.

=head2 _fill_group_cells()

After doing a C<layout()>, we need to add the group to each cell based on
what group the nearest node is in.

This routine will also find the label cell for each group, and repair
edge/node damage done by the splicing.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2007 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut
#############################################################################
# Find paths from node to node in a Manhattan-style grid via A*.
#
# (c) by Tels - part of Graph::Easy
#############################################################################

package Graph::Easy::Layout::Scout;

$VERSION = '0.25';

#############################################################################
#############################################################################

package Graph::Easy;

use strict;
use Graph::Easy::Node::Cell;
use Graph::Easy::Edge::Cell qw/
  EDGE_SHORT_E EDGE_SHORT_W EDGE_SHORT_N EDGE_SHORT_S

  EDGE_SHORT_BD_EW EDGE_SHORT_BD_NS
  EDGE_SHORT_UN_EW EDGE_SHORT_UN_NS

  EDGE_START_E EDGE_START_W EDGE_START_N EDGE_START_S

  EDGE_END_E EDGE_END_W EDGE_END_N EDGE_END_S

  EDGE_N_E EDGE_N_W EDGE_S_E EDGE_S_W

  EDGE_N_W_S EDGE_S_W_N EDGE_E_S_W EDGE_W_S_E

  EDGE_LOOP_NORTH EDGE_LOOP_SOUTH EDGE_LOOP_WEST EDGE_LOOP_EAST

  EDGE_HOR EDGE_VER EDGE_HOLE

  EDGE_S_E_W EDGE_N_E_W EDGE_E_N_S EDGE_W_N_S

  EDGE_LABEL_CELL
  EDGE_TYPE_MASK
  EDGE_ARROW_MASK
  EDGE_FLAG_MASK
  EDGE_START_MASK
  EDGE_END_MASK
  EDGE_NO_M_MASK
 /;

#############################################################################

# mapping edge type (HOR, VER, NW etc) and dx/dy to startpoint flag
my $start_points = {
#               [ dx == 1, 	dx == -1,     dy == 1,      dy == -1 ,
#                 dx == 1, 	dx == -1,     dy == 1,      dy == -1 ]
  EDGE_HOR() => [ EDGE_START_W, EDGE_START_E, 0,	    0 			,
		  EDGE_END_E,   EDGE_END_W,   0,	    0,			],
  EDGE_VER() => [ 0,		0, 	      EDGE_START_N, EDGE_START_S 	,
		  0,		0,	      EDGE_END_S,   EDGE_END_N,		],
  EDGE_N_E() => [ 0,		EDGE_START_E, EDGE_START_N, 0		 	,
		  EDGE_END_E,	0,	      0, 	    EDGE_END_N, 	],
  EDGE_N_W() => [ EDGE_START_W,	0, 	      EDGE_START_N, 0			,
		  0,	        EDGE_END_W,   0,	    EDGE_END_N,		],
  EDGE_S_E() => [ 0,		EDGE_START_E, 0,	    EDGE_START_S 	,
		  EDGE_END_E,   0,            EDGE_END_S,   0,			],
  EDGE_S_W() => [ EDGE_START_W,	0, 	      0,	    EDGE_START_S	,
		  0,		EDGE_END_W,   EDGE_END_S,   0,			],
  };

my $start_to_end = {
  EDGE_START_W() => EDGE_END_W(),
  EDGE_START_E() => EDGE_END_E(),
  EDGE_START_S() => EDGE_END_S(),
  EDGE_START_N() => EDGE_END_N(),
  };

sub _end_points
  {
  # modify last field of path to be the correct endpoint; and the first field
  # to be the correct startpoint:
  my ($self, $edge, $coords, $dx, $dy) = @_;
  
  return $coords if $edge->undirected();

  # there are two cases (for each dx and dy)
  my $i = 0;					# index 0,1
  my $co = 2;
  my $case;

  for my $d ($dx,$dy,$dx,$dy)
    {
    next if $d == 0;

    my $type = $coords->[$co] & EDGE_TYPE_MASK;

    $case = 0; $case = 1 if $d == -1;

    # modify first/last cell
    my $t = $start_points->{ $type }->[ $case + $i ];
    # on bidirectional edges, turn START_X into END_X
    $t = $start_to_end->{$t} || $t if $edge->{bidirectional};

    $coords->[$co] += $t;

    } continue {
    $i += 2; 					# index 2,3, 4,5 etc
    $co = -1 if $i == 4;			# modify now last cell
    }
  $coords;
  }

sub _find_path
  {
  # Try to find a path between two nodes. $options contains direction
  # preferences. Returns a list of cells like:
  # [ $x,$y,$type, $x1,$y1,$type1, ...]
  my ($self, $src, $dst, $edge) = @_;

  # one node pointing back to itself?
  if ($src == $dst)
    {
    my $rc = $self->_find_path_loop($src,$edge);
    return $rc unless scalar @$rc == 0;
    }

  # If one of the two nodes is bigger than 1 cell, use _find_path_astar(),
  # because it automatically handles all the possibilities:
  return $self->_find_path_astar($edge)
    if ($src->is_multicelled() || $dst->is_multicelled() || $edge->has_ports());
  
  my ($x0, $y0) = ($src->{x}, $src->{y});
  my ($x1, $y1) = ($dst->{x}, $dst->{y});
  my $dx = ($x1 - $x0) <=> 0;
  my $dy = ($y1 - $y0) <=> 0;
    
  my $cells = $self->{cells};
  my @coords;
  my ($x,$y) = ($x0,$y0);			# starting pos

  ###########################################################################
  # below follow some shortcuts for easy things like straight paths:

  print STDERR "#  dx,dy: $dx,$dy\n" if $self->{debug};

  if ($dx == 0 || $dy == 0)
    {
    # try straight path to target:
 
    print STDERR "#  $src->{x},$src->{y} => $dst->{x},$dst->{y} - trying short path\n" if $self->{debug};

    # distance to node:
    my $dx1 = ($x1 - $x0);
    my $dy1 = ($y1 - $y0);
    ($x,$y) = ($x0+$dx,$y0+$dy);			# starting pos

    if ((abs($dx1) == 2) || (abs($dy1) == 2))
      {
      if (!exists ($cells->{"$x,$y"}))
        {
        # a single step for this edge:
        my $type = EDGE_LABEL_CELL;
        # short path
        if ($edge->bidirectional())
	  {
          $type += EDGE_SHORT_BD_EW if $dy == 0;
          $type += EDGE_SHORT_BD_NS if $dx == 0;
          }
        elsif ($edge->undirected())
          {
          $type += EDGE_SHORT_UN_EW if $dy == 0;
          $type += EDGE_SHORT_UN_NS if $dx == 0;
          }
        else
          {
          $type += EDGE_SHORT_E if ($dx ==  1 && $dy ==  0);
          $type += EDGE_SHORT_S if ($dx ==  0 && $dy ==  1);
          $type += EDGE_SHORT_W if ($dx == -1 && $dy ==  0);
          $type += EDGE_SHORT_N if ($dx ==  0 && $dy == -1);
          }
	# if one of the end points of the edge is of shape 'edge'
	# remove end/start flag
        if (($edge->{to}->attribute('shape') ||'') eq 'edge')
	  {
	  # we only need to remove one start point, namely the one at the "end"
	  if ($dx > 0)
	    {
	    $type &= ~EDGE_START_E;
	    }
	  elsif ($dx < 0)
	    {
	    $type &= ~EDGE_START_W;
	    }
	  }
        if (($edge->{from}->attribute('shape') ||'') eq 'edge')
	  {
	  $type &= ~EDGE_START_MASK;
	  }

        return [ $x, $y, $type ];			# return a short EDGE
        }
      }

    my $type = EDGE_HOR; $type = EDGE_VER if $dx == 0;	# - or |
    my $done = 0;
    my $label_done = 0;
    while (3 < 5)		# endless loop
      {
      # Since we do not handle crossings here, A* will be tried if we hit an
      # edge in this test.
      $done = 1, last if exists $cells->{"$x,$y"};	# cell already full

      # the first cell gets the label
      my $t = $type; $t += EDGE_LABEL_CELL if $label_done++ == 0;

      push @coords, $x, $y, $t;				# good one, is free
      $x += $dx; $y += $dy;				# next field
      last if ($x == $x1) && ($y == $y1);
      }

    if ($done == 0)
      {
      print STDERR "#  success for ", scalar @coords / 3, " steps in path\n" if $self->{debug};
      # return all fields of path
      return $self->_end_points($edge, \@coords, $dx, $dy);
      }

    } # end else straight path try

  ###########################################################################
  # Try paths with one bend:

  # ($dx != 0 && $dy != 0) => path with one bend
  # XXX TODO:
  # This could be handled by A*, too, but it would be probably a bit slower.
  else
    {
    # straight path not possible, since x0 != x1 AND y0 != y1

    #           "  |"                        "|   "
    # try first "--+" (aka hor => ver), then "+---" (aka ver => hor)
    my $done = 0;

    print STDERR "#  bend path from $x,$y\n" if $self->{debug};

    # try hor => ver
    my $type = EDGE_HOR;

    my $label = 0;						# attach label?
    $label = 1 if ref($edge) && ($edge->label()||'') eq '';	# no label?
    $x += $dx;
    while ($x != $x1)
      {
      $done++, last if exists $cells->{"$x,$y"};	# cell already full
      print STDERR "#  at $x,$y\n" if $self->{debug};
      my $t = $type; $t += EDGE_LABEL_CELL if $label++ == 0;
      push @coords, $x, $y, $t;				# good one, is free
      $x += $dx;					# next field
      };

    # check the bend itself     
    $done++ if exists $cells->{"$x,$y"};	# cell already full

    if ($done == 0)
      {
      my $type_bend = _astar_edge_type ($x-$dx,$y, $x,$y, $x,$y+$dy);
 
      push @coords, $x, $y, $type_bend;			# put in bend
      print STDERR "# at $x,$y\n" if $self->{debug};
      $y += $dy;
      $type = EDGE_VER;
      while ($y != $y1)
        {
        $done++, last if exists $cells->{"$x,$y"};	# cell already full
	print STDERR "# at $x,$y\n" if $self->{debug};
        push @coords, $x, $y, $type;			# good one, is free
        $y += $dy;
        } 
      }

    if ($done != 0)
      {
      $done = 0;
      # try ver => hor
      print STDERR "# hm, now trying first vertical, then horizontal\n" if $self->{debug};
      $type = EDGE_VER;

      @coords = ();					# drop old version
      ($x,$y) = ($x0, $y0 + $dy);			# starting pos
      while ($y != $y1)
        {
        $done++, last if exists $cells->{"$x,$y"};	# cell already full
        print STDERR "# at $x,$y\n" if $self->{debug};
        push @coords, $x, $y, $type;			# good one, is free
        $y += $dy;					# next field
        };

      # check the bend itself     
      $done++ if exists $cells->{"$x,$y"};		# cell already full

      if ($done == 0)
        {
        my $type_bend = _astar_edge_type ($x,$y-$dy, $x,$y, $x+$dx,$y);

        push @coords, $x, $y, $type_bend;		# put in bend
        print STDERR "# at $x,$y\n" if $self->{debug};
        $x += $dx;
        my $label = 0;					# attach label?
        $label = 1 if $edge->label() eq '';		# no label?
        $type = EDGE_HOR;
        while ($x != $x1)
          {
          $done++, last if exists $cells->{"$x,$y"};	# cell already full
	  print STDERR "# at $x,$y\n" if $self->{debug};
          my $t = $type; $t += EDGE_LABEL_CELL if $label++ == 0;
          push @coords, $x, $y, $t;			# good one, is free
	  $x += $dx;
          } 
        }
      }

    if ($done == 0)
      {
      print STDERR "# success for ", scalar @coords / 3, " steps in path\n" if $self->{debug};
      # return all fields of path
      return $self->_end_points($edge, \@coords, $dx, $dy);
      }

    print STDERR "# no success\n" if $self->{debug};

    } # end path with $dx and $dy

  $self->_find_path_astar($edge);		# try generic approach as last hope
  }

sub _find_path_loop
  {
  # find a path from one node back to itself
  my ($self, $src, $edge) = @_;

  print STDERR "# Finding looping path from $src->{name} to $src->{name}\n" if $self->{debug};

  my ($n, $cells, $d, $type, $loose) = @_;

  # get a list of all places

  my @places = $src->_near_places( 
    $self->{cells}, 1, [
      EDGE_LOOP_EAST,
      EDGE_LOOP_SOUTH,
      EDGE_LOOP_WEST,
      EDGE_LOOP_NORTH,
    ], 0, 90);
  
  my $flow = $src->flow();

  # We cannot use _shuffle_dir() here, because self-loops
  # are tried in a different order:

  # the default (east)
  my $index = [
    EDGE_LOOP_NORTH,
    EDGE_LOOP_SOUTH,
    EDGE_LOOP_WEST,
    EDGE_LOOP_EAST,
   ];

  # west
  $index = [
    EDGE_LOOP_SOUTH,
    EDGE_LOOP_NORTH,
    EDGE_LOOP_EAST,
    EDGE_LOOP_WEST,
   ] if $flow == 270;

  # north
  $index = [
    EDGE_LOOP_WEST,
    EDGE_LOOP_EAST,
    EDGE_LOOP_SOUTH,
    EDGE_LOOP_NORTH,
   ] if $flow == 0;
  
  # south
  $index = [
    EDGE_LOOP_EAST,
    EDGE_LOOP_WEST,
    EDGE_LOOP_NORTH,
    EDGE_LOOP_SOUTH,
   ] if $flow == 180;
  
  for my $this_try (@$index)
    {
    my $idx = 0;
    while ($idx < @places)
      {
      print STDERR "# Trying $places[$idx+0],$places[$idx+1]\n" if $self->{debug};
      next unless $places[$idx+2] == $this_try;
      
      # build a path from the returned piece
      my @rc = ($places[$idx], $places[$idx+1], $places[$idx+2]);

      print STDERR "# Trying $rc[0],$rc[1]\n" if $self->{debug};

      next unless $self->_path_is_clear(\@rc);

      print STDERR "# Found looping path\n" if $self->{debug};
      return \@rc;
      } continue { $idx += 3; } 
    }

  [];		# no path found
  }

#############################################################################
#############################################################################

# This package represents a simple/cheap/fast heap:
package Graph::Easy::Heap;

require Graph::Easy::Base;
our @ISA = qw/Graph::Easy::Base/;

use strict;

sub _init
  {
  my ($self,$args) = @_;

  $self->{_heap} = [ ];

  $self;
  }

sub add
  {
  # add one element to the heap
  my ($self,$elem) = @_;

  my $heap = $self->{_heap};

  # heap empty?
  if (@$heap == 0)
    {
    push @$heap, $elem;
    }
  # smaller than first elem?
  elsif ($elem->[0] < $heap->[0]->[0])
    {
    #print STDERR "# $elem->[0] is smaller then first elem $heap->[0]->[0] (with ", scalar @$heap," elems on heap)\n";
    unshift @$heap, $elem;
    }
  # bigger than or equal to last elem?
  elsif ($elem->[0] > $heap->[-1]->[0])
    {
    #print STDERR "# $elem->[0] is bigger then last elem $heap->[-1]->[0] (with ", scalar @$heap," elems on heap)\n";
    push @$heap, $elem;
    }
  else
    {
    # insert the elem at the right position

    # if we have less than X elements, use linear search
    my $el = $elem->[0];
    if (scalar @$heap < 10)
      {
      my $i = 0;
      for my $e (@$heap)
        {
        if ($e->[0] > $el)
          {
          splice (@$heap, $i, 0, $elem);		# insert $elem
          return undef;
          }
        $i++;
        }
      # else, append at the end
      push @$heap, $elem;
      }
    else
      {
      # use binary search
      my $l = 0; my $r = scalar @$heap;
      while (($r - $l) > 2)
        {
        my $m = int((($r - $l) / 2) + $l);
#        print "l=$l r=$r m=$m el=$el heap=$heap->[$m]->[0]\n";
        if ($heap->[$m]->[0] <= $el)
          {
          $l = $m;
          }
        else
          {
          $r = $m;
          }
        }
      while ($l < @$heap)
        {
        if ($heap->[$l]->[0] > $el)
          {
          splice (@$heap, $l, 0, $elem);		# insert $elem
          return undef;
          }
        $l++;
        }
      # else, append at the end
      push @$heap, $elem;
      }
    }
  undef;
  }

sub elements
  {
  scalar @{$_[0]->{_heap}};
  }

sub extract_top
  {
  # remove and return the top elemt
  shift @{$_[0]->{_heap}};
  }

sub delete
  {
  # Find an element by $x,$y and delete it
  my ($self, $x, $y) = @_;

  my $heap = $self->{_heap};
  
  my $i = 0;
  for my $e (@$heap)
    {
    if ($e->[1] == $x && $e->[2] == $y)
      {
      splice (@$heap, $i, 1);
      return;
      }
    $i++;
    }

  $self;
  }

sub sort_sub
  {
  my ($self) = shift;

  $self->{_sort} = shift;
  }

#############################################################################
#############################################################################

package Graph::Easy;

# Generic pathfinding via the A* algorithm:
# See http://bloodgate.com/perl/graph/astar.html for some background.

sub _astar_modifier
  {
  # calculate the cost for the path at cell x1,y1 
  my ($x1,$y1,$x,$y,$px,$py, $cells) = @_;

  my $add = 1;

  if (defined $x1)
    {
    my $xy = "$x1,$y1";
    # add a harsh penalty for crossing an edge, meaning we can travel many
    # fields to go around.
    $add += 30 if ref($cells->{$xy}) && $cells->{$xy}->isa('Graph::Easy::Edge');
    }
 
  if (defined $px)
    {
    # see whether the new position $x1,$y1 is a continuation from $px,$py => $x,$y
    # e.g. if from we go down from $px,$py to $x,$y, then anything else then $x,$y+1 will
    # get a penalty
    my $dx1 = ($px-$x) <=> 0;
    my $dy1 = ($py-$y) <=> 0;
    my $dx2 = ($x-$x1) <=> 0;
    my $dy2 = ($y-$y1) <=> 0;
    $add += 6 unless $dx1 == $dx2 || $dy1 == $dy2;
    }
  $add;
  }

sub _astar_distance
  {
  # calculate the manhattan distance between x1,y1 and x2,y2
#  my ($x1,$y1,$x2,$y2) = @_;

  my $dx = abs($_[2] - $_[0]);
  my $dy = abs($_[3] - $_[1]);

  # plus 1 because we need to go around one corner if $dx != 0 && $dx != 0
  $dx++ if $dx != 0 && $dy != 0;

  $dx + $dy;
  }

my $edge_type = {
    '0,1,-1,0' => EDGE_N_W,
    '0,1,0,1' => EDGE_VER,
    '0,1,1,0' => EDGE_N_E,

    '-1,0,0,-1' => EDGE_N_E,
    '-1,0,-1,0' => EDGE_HOR,
    '-1,0,0,1' => EDGE_S_E,

    '0,-1,-1,0' => EDGE_S_W,
    '0,-1,0,-1' => EDGE_VER,
    '0,-1,1,0' => EDGE_S_E,

    '1,0,0,-1' => EDGE_N_W,
    '1,0,1,0' => EDGE_HOR,
    '1,0,0,1' => EDGE_S_W,

    # loops (left-right-left etc)
    '0,-1,0,1' => EDGE_N_W_S,
    '0,1,0,-1' => EDGE_S_W_N,
    '1,0,-1,0' => EDGE_E_S_W,
    '-1,0,1,0' => EDGE_W_S_E,
  };

sub _astar_edge_type
  {
  # from three consecutive positions calculate the edge type (VER, HOR, N_W etc)
  my ($x,$y, $x1,$y1, $x2, $y2) = @_;

  my $dx1 = ($x1 - $x) <=> 0;
  my $dy1 = ($y1 - $y) <=> 0;

  my $dx2 = ($x2 - $x1) <=> 0;
  my $dy2 = ($y2 - $y1) <=> 0;

  # in some cases we get (0,-1,0,0), so set the missing parts
  ($dx2,$dy2) = ($dx1,$dy1) if $dx2 == 0 && $dy2 == 0;
  # can this case happen?
  ($dx1,$dy1) = ($dx2,$dy2) if $dx1 == 0 && $dy1 == 0;

  # return correct type depending on differences
  $edge_type->{"$dx1,$dy1,$dx2,$dy2"} || EDGE_HOR;
  }

sub _astar_near_nodes
  {
  # return possible next nodes from $nx,$ny
  my ($self, $nx, $ny, $cells, $closed, $min_x, $min_y, $max_x, $max_y) = @_;

  my @places = ();

  my @tries  = (	# ordered E,S,W,N:
    $nx + 1, $ny, 	# right
    $nx, $ny + 1,	# down
    $nx - 1, $ny,	# left
    $nx, $ny - 1,	# up
    );

  # on crossings, only allow one direction (NS or EW)
  my $type = EDGE_CROSS;
  # including flags, because only flagless edges may be crossed
  $type = $cells->{"$nx,$ny"}->{type} if exists $cells->{"$nx,$ny"};
  if ($type == EDGE_HOR)
    {
    @tries  = (
      $nx, $ny + 1,	# down
      $nx, $ny - 1,	# up
    );
    }
  elsif ($type == EDGE_VER)
    {
    @tries  = (
      $nx + 1, $ny, 	# right
      $nx - 1, $ny,	# left
    );
    }

  # This loop does not check whether the position is already open or not,
  # the caller will later check if the already-open position needs to be
  # replaced by one with a lower cost.

  my $i = 0;
  while ($i < @tries)
    {
    my ($x,$y) = ($tries[$i], $tries[$i+1]);

    print STDERR "# $min_x,$min_y => $max_x,$max_y\n" if $self->{debug} > 2;

    # drop cells outside our working space:
    next if $x < $min_x || $x > $max_x || $y < $min_y || $y > $max_y;

    my $p = "$x,$y";
    print STDERR "# examining pos $p\n" if $self->{debug} > 2;

    next if exists $closed->{$p};

    if (exists $cells->{$p} && ref($cells->{$p}) && $cells->{$p}->isa('Graph::Easy::Edge'))
      {
      # If the existing cell is an VER/HOR edge, then we may cross it
      my $type = $cells->{$p}->{type};	# including flags, because only flagless edges
					# may be crossed

      push @places, $x, $y if ($type == EDGE_HOR) || ($type == EDGE_VER);
      next;
      }
    next if exists $cells->{$p};	# uncrossable cell

    push @places, $x, $y;

    } continue { $i += 2; }
 
  @places;
  }

sub _astar_boundaries
  {
  # Calculate boundaries for area that A* should not leave.
  my $self = shift;

  my $cache = $self->{cache};

  return ( $cache->{min_x}-1, $cache->{min_y}-1, 
	   $cache->{max_x}+1, $cache->{max_y}+1 ) if defined $cache->{min_x};

  my ($min_x, $min_y, $max_x, $max_y);

  my $cells = $self->{cells};

  $min_x = 10000000;
  $min_y = 10000000;
  $max_x = -10000000;
  $max_y = -10000000;

  for my $c (keys %$cells)
    {
    my ($x,$y) = split /,/, $c;
    $min_x = $x if $x < $min_x;
    $min_y = $y if $y < $min_y;
    $max_x = $x if $x > $max_x;
    $max_y = $y if $y > $max_y;
    }

  print STDERR "# A* working space boundaries: $min_x, $min_y, $max_x, $max_y\n" if $self->{debug};

  ( $cache->{min_x}, $cache->{min_y}, $cache->{max_x}, $cache->{max_y} ) = 
  ($min_x, $min_y, $max_x, $max_y);

  # make the area one bigger in each direction
  $min_x --; $min_y --; $max_x ++; $max_y ++;
  ($min_x, $min_y, $max_x, $max_y);
  }

# on edge pieces, select start fields (left/right of a VER, above/below of a HOR etc)
# contains also for each starting position the joint-type
my $next_fields =
  {
  EDGE_VER() => [ -1,0, EDGE_W_N_S, +1,0, EDGE_E_N_S ],
  EDGE_HOR() => [ 0,-1, EDGE_N_E_W, 0,+1, EDGE_S_E_W ],
  EDGE_N_E() => [ 0,+1, EDGE_E_N_S, -1,0, EDGE_N_E_W ],		# |_
  EDGE_N_W() => [ 0,+1, EDGE_W_N_S, +1,0, EDGE_N_E_W ],		# _|
  EDGE_S_E() => [ 0,-1, EDGE_E_N_S, -1,0, EDGE_S_E_W ],
  EDGE_S_W() => [ 0,-1, EDGE_W_N_S, +1,0, EDGE_S_E_W ],
  };

# on edge pieces, select end fields (left/right of a VER, above/below of a HOR etc)
# contains also for each end position the joint-type
my $prev_fields =
  {
  EDGE_VER() => [ -1,0, EDGE_W_N_S, +1,0, EDGE_E_N_S ],
  EDGE_HOR() => [ 0,-1, EDGE_N_E_W, 0,+1, EDGE_S_E_W ],
  EDGE_N_E() => [ 0,+1, EDGE_E_N_S, -1,0, EDGE_N_E_W ],		# |_
  EDGE_N_W() => [ 0,+1, EDGE_W_N_S, +1,0, EDGE_N_E_W ],		# _|
  EDGE_S_E() => [ 0,-1, EDGE_E_N_S, -1,0, EDGE_S_E_W ],
  EDGE_S_W() => [ 0,-1, EDGE_W_N_S, +1,0, EDGE_S_E_W ],
  };

sub _get_joints
  { 
  # from a list of shared, already placed edges, get possible start/end fields
  my ($self, $shared, $mask, $types, $cells, $next_fields) = @_;

  # XXX TODO: do not do this for edges with no free places for joints

  # take each cell from all edges shared, already placed edges as start-point
  for my $e (@$shared)
    {
    for my $c (@{$e->{cells}})
      {
      my $type = $c->{type} & EDGE_TYPE_MASK;

      next unless exists $next_fields->{ $type };

      # don't consider end/start (depending on $mask) cells

      # do not join EDGE_HOR or EDGE_VER, but join corner pieces
      next if ( ($type == EDGE_HOR()) || 
		($type == EDGE_VER()) ) &&
		($c->{type} & $mask);

      my $fields = $next_fields->{$type};

      my ($px,$py) = ($c->{x},$c->{y});
      my $i = 0;
      while ($i < @$fields)
	{
	my ($sx,$sy, $jt) = ($fields->[$i], $fields->[$i+1], $fields->[$i+2]);
	$sx += $px; $sy += $py; $i += 3;
        my $sxsy = "$sx,$sy";
        # don't add the field twice
	next if exists $cells->{$sxsy};
	$cells->{$sxsy} = [ $sx, $sy, undef, $px, $py ];
	# keep eventually set start/end points on the original cell
	$types->{$sxsy} = $jt + ($c->{type} & EDGE_FLAG_MASK);
	} 
      }
    }
 
  my @R;
  # convert hash to array
  for my $s (values %{$cells})
    {
    push @R, @$s;
    }
  @R;
  }

sub _join_edge
  {
  # Find out whether an edge sharing an ending point with the source edge
  # runs alongside the source node, if so, convert it to a joint:
  my ($self, $node, $edge, $shared, $end) = @_;

  # we check the sides B,C,D and E for HOR and VER edge pices:
  #   --D--
  # | +---+ |
  # E | A | B
  # | +---+ |
  #   --C--

  my $flags = 
   [ 
      EDGE_W_N_S + EDGE_START_W,
      EDGE_N_E_W + EDGE_START_N,
      EDGE_E_N_S + EDGE_START_E,
      EDGE_S_E_W + EDGE_START_S,
   ];
  $flags = 
   [ 
      EDGE_W_N_S + EDGE_END_W,
      EDGE_N_E_W + EDGE_END_N,
      EDGE_E_N_S + EDGE_END_E,
      EDGE_S_E_W + EDGE_END_S,
   ] if $end || $edge->{bidirectional};
  
  my $cells = $self->{cells};
  my @places = $node->_near_places($cells, 1, # distance 1
   $flags, 'loose'); 

  my $i = 0;
  while ($i < @places)
    {
    my ($x,$y) = ($places[$i], $places[$i+1]); $i += 3;
    
    next unless exists $cells->{"$x,$y"};		# empty space?
    # found some cell, check that it is a EDGE_HOR or EDGE_VER
    my $cell = $cells->{"$x,$y"};
    next unless $cell->isa('Graph::Easy::Edge::Cell');

    my $cell_type = $cell->{type} & EDGE_TYPE_MASK;

    next unless $cell_type == EDGE_HOR || $cell_type == EDGE_VER;

    # the cell must belong to one of the shared edges
    my $e = $cell->{edge}; local $_;
    next unless scalar grep { $e == $_ } @$shared;

    # make the cell at the current pos a joint
    $cell->_make_joint($edge,$places[$i-1]);

    # The layouter will check that each edge has a cell, so add a dummy one to
    # $edge to make it happy:
    Graph::Easy::Edge::Cell->new( type => EDGE_HOLE, edge => $edge, x => $x, y => $y );

    return [];					# path is empty
    }

  undef;		# did not find an edge cell that can be used as joint
  }

sub _find_path_astar
  {
  # Find a path with the A* algorithm for the given edge (from node A to B)
  my ($self,$edge) = @_;

  my $cells = $self->{cells};
  my $src = $edge->{from};
  my $dst = $edge->{to};

  print STDERR "# A* from $src->{x},$src->{y} to $dst->{x},$dst->{y}\n" if $self->{debug};

  my $start_flags = [
    EDGE_START_W,
    EDGE_START_N,
    EDGE_START_E,
    EDGE_START_S,
  ]; 

  my $end_flags = [
    EDGE_END_W,
    EDGE_END_N,
    EDGE_END_E,
    EDGE_END_S,
  ]; 

  # if the target/source node is of shape "edge", remove the endpoint
  if ( ($edge->{to}->attribute('shape')) eq 'edge')
    {
    $end_flags = [ 0,0,0,0 ];
    }
  if ( ($edge->{from}->attribute('shape')) eq 'edge')
    {
    $start_flags = [ 0,0,0,0 ];
    }

  my ($s_p,@ss_p) = $edge->port('start');
  my ($e_p,@ee_p) = $edge->port('end');
  my (@A, @B);					# Start/Stop positions
  my @shared_start;
  my @shared_end;

  my $joint_type = {};
  my $joint_type_end = {};

  my $start_cells = {};
  my $end_cells = {};

  ###########################################################################
  # end fields first (because maybe an edge runs alongside the node)

  # has a end point restriction
  @shared_end = $edge->{to}->edges_at_port('end', $e_p, $ee_p[0]) if defined $e_p && @ee_p == 1;

  my @shared = ();
  # filter out all non-placed edges (this will also filter out $edge)
  for my $s (@shared_end)
    {
    push @shared, $s if @{$s->{cells}} > 0;
    }

  my $per_field = 5;			# for shared: x,y,undef, px,py
  if (@shared > 0)
    {
    # more than one edge share the same end port, and one of the others was
    # already placed

    print STDERR "#  edge from '$edge->{from}->{name}' to '$edge->{to}->{name}' shares end port with ",
	scalar @shared, " other edge(s)\n" if $self->{debug};

    # if there is one of the already-placed edges running alongside the src
    # node, we can just convert the field to a joint and be done
    my $path = $self->_join_edge($src,$edge,\@shared);
    return $path if $path;				# already done?

    @B = $self->_get_joints(\@shared, EDGE_START_MASK, $joint_type_end, $end_cells, $prev_fields);
    }
  else
    {
    # potential stop positions
    @B = $dst->_near_places($cells, 1, $end_flags, 1);	# distance = 1: slots

    # the edge has a port description, limiting the end places
    @B = $dst->_allowed_places( \@B, $dst->_allow( $e_p, @ee_p ), 3)
      if defined $e_p;

    $per_field = 3;			# x,y,type
    }

  return unless scalar @B > 0;			# no free slots on target node?

  ###########################################################################
  # start fields

  # has a starting point restriction:
  @shared_start = $edge->{from}->edges_at_port('start', $s_p, $ss_p[0]) if defined $s_p && @ss_p == 1;

  @shared = ();
  # filter out all non-placed edges (this will also filter out $edge)
  for my $s (@shared_start)
    {
    push @shared, $s if @{$s->{cells}} > 0;
    }

  if (@shared > 0)
    {
    # More than one edge share the same start port, and one of the others was
    # already placed, so we just run along until we catch it up with a joint:

    print STDERR "#  edge from '$edge->{from}->{name}' to '$edge->{to}->{name}' shares start port with ",
	scalar @shared, " other edge(s)\n" if $self->{debug};

    # if there is one of the already-placed edges running alongside the src
    # node, we can just convert the field to a joint and be done
    my $path = $self->_join_edge($dst, $edge, \@shared, 'end');
    return $path if $path;				# already done?

    @A = $self->_get_joints(\@shared, EDGE_END_MASK, $joint_type, $start_cells, $next_fields);
    }
  else
    {
    # from SRC to DST

    # get all the starting positions
    # distance = 1: slots, generate starting types, the direction is shifted
    # by 90° counter-clockwise

    my $s = $start_flags; $s = $end_flags if $edge->{bidirectional};
    my @start = $src->_near_places($cells, 1, $s, 1, $src->_shift(-90) );

    # the edge has a port description, limiting the start places
    @start = $src->_allowed_places( \@start, $src->_allow( $s_p, @ss_p ), 3)
      if defined $s_p;

    return unless @start > 0;			# no free slots on start node?

    my $i = 0;
    while ($i < scalar @start)
      {
      my $sx = $start[$i]; my $sy = $start[$i+1]; my $type = $start[$i+2]; $i += 3;

      # compute the field inside the node from where $sx,$sy is reached:
      my $px = $sx; my $py = $sy;
      if ($sy < $src->{y} || $sy >= $src->{y} + $src->{cy})
        {
        $py = $sy + 1 if $sy < $src->{y};		# above
        $py = $sy - 1 if $sy > $src->{y};		# below
        }
      else
        {
        $px = $sx + 1 if $sx < $src->{x};		# right
        $px = $sx - 1 if $sx > $src->{x};		# left
        }

      push @A, ($sx, $sy, $type, $px, $py);
      }
    }

  ###########################################################################
  # use A* to finally find the path:

  my $path = $self->_astar(\@A,\@B,$edge, $per_field);

  if (@$path > 0 && keys %$start_cells > 0)
    {
    # convert the edge piece of the starting edge-cell to a joint
    my ($x, $y) = ($path->[0],$path->[1]);
    my $xy = "$x,$y";
    my ($sx,$sy,$t,$px,$py) = @{$start_cells->{$xy}};

    my $jt = $joint_type->{"$sx,$sy"};
    $cells->{"$px,$py"}->_make_joint($edge,$jt);
    }

  if (@$path > 0 && keys %$end_cells > 0)
    {
    # convert the edge piece of the starting edge-cell to a joint
    my ($x, $y) = ($path->[-3],$path->[-2]);
    my $xy = "$x,$y";
    my ($sx,$sy,$t,$px,$py) = @{$end_cells->{$xy}};

    my $jt = $joint_type_end->{"$sx,$sy"};
    $cells->{"$px,$py"}->_make_joint($edge,$jt);
    }

  $path;
  }

sub _astar
  {
  # The core A* algorithm, finds a path from a given list of start
  # positions @A to and of the given stop positions @B.
  my ($self, $A, $B, $edge, $per_field) = @_;

  my @start = @$A;
  my @stop = @$B;
  my $stop = scalar @stop;

  my $src = $edge->{from};
  my $dst = $edge->{to};
  my $cells = $self->{cells};

  my $open = Graph::Easy::Heap->new();	# to find smallest elem fast
  my $open_by_pos = {};			# to find open nodes by pos
  my $closed = {};			# to find closed nodes by pos

  my $elem;

  # The boundaries of objects in $cell, e.g. the area that the algorithm shall
  # never leave.
  my ($min_x, $min_y, $max_x, $max_y) = $self->_astar_boundaries();

  # Max. steps to prevent endless searching in case of bugs like endless loops.
  my $tries = 0; my $max_tries = 2000000;

  # count how many times we did A*
  $self->{stats}->{astar}++;

  ###########################################################################
  ###########################################################################
  # put the start positions into OPEN

  my $i = 0; my $bias = 0;
  while ($i < scalar @start)
    {
    my ($sx,$sy,$type,$px,$py) = 
     ($start[$i],$start[$i+1],$start[$i+2],$start[$i+3],$start[$i+4]);
    $i += 5;

    my $cell = $cells->{"$sx,$sy"}; my $rcell = ref($cell);
    next if $rcell && $rcell !~ /::Edge/;

    my $t = 0; $t = $cell->{type} & EDGE_NO_M_MASK if $rcell =~ /::Edge/;
    next if $t != 0 && $t != EDGE_HOR && $t != EDGE_VER;

    # For each start point, calculate the distance to each stop point, then use
    # the smallest as value:
    my $lowest_x = $stop[0]; my $lowest_y = $stop[1];
    my $lowest = _astar_distance($sx,$sy, $stop[0], $stop[1]);
    for (my $u = $per_field; $u < $stop; $u += $per_field)
      {
      my $dist = _astar_distance($sx,$sy, $stop[$u], $stop[$u+1]);
      ($lowest_x, $lowest_y) = ($stop[$u],$stop[$u+1]) if $dist < $lowest;
      $lowest = $dist if $dist < $lowest;
      }


    # add a penalty for crossings
    my $malus = 0; $malus = 30 if $t != 0;
    $malus += _astar_modifier($px,$py, $sx, $sy, $sx, $sy);
    $open->add( [ $lowest, $sx, $sy, $px, $py, $type, 1 ] );

    my $o = $malus + $bias + $lowest;
    print STDERR "#   adding open pos $sx,$sy ($o = $malus + $bias + $lowest) at ($lowest_x,$lowest_y)\n"
	 if $self->{debug} > 1;

    # The cost to reach the starting node is obviously 0. That means that there is
    # a tie between going down/up if both possibilities are equal likely. We insert
    # a small bias here that makes the prefered order east/south/west/north. Instead
    # the algorithmn exploring both way and terminating arbitrarily on the one that
    # first hits the target, it will explore only one.
    $open_by_pos->{"$sx,$sy"} = $o;

    $bias += $self->{_astar_bias} || 0;
    } 

  ###########################################################################
  ###########################################################################
  # main A* loop

  my $stats = $self->{stats};

  STEP:
  while( defined( $elem = $open->extract_top() ) )
    {
    $stats->{astar_steps}++ if $self->{debug};

    # hard limit on number of steps todo
    if ($tries++ > $max_tries)
      {
      $self->warn("A* reached maximum number of tries ($max_tries), giving up."); 
      return [];
      }

    print STDERR "#  Smallest elem from ", $open->elements(), 
	" elems is: weight=", $elem->[0], " at $elem->[1],$elem->[2]\n" if $self->{debug} > 1;
    my ($val, $x,$y, $px,$py, $type, $do_stop) = @$elem;

    my $key = "$x,$y";
    # move node into CLOSE and remove from OPEN
    my $g = $open_by_pos->{$key} || 0;
    $closed->{$key} = [ $px, $py, $val - $g, $g, $type, $do_stop ];
    delete $open_by_pos->{$key};

    # we are done when we hit one of the potential stop positions
    for (my $i = 0; $i < $stop; $i += $per_field)
      {
      # reached one stop position?
      if ($x == $stop[$i] && $y == $stop[$i+1])
        {
        $closed->{$key}->[4] += $stop[$i+2] if defined $stop[$i+2];
	# store the reached stop position if it is known
	if ($per_field > 3)
	  {
	  $closed->{$key}->[6] = $stop[$i+3];
	  $closed->{$key}->[7] = $stop[$i+4];
          print STDERR "#  Reached stop position $x,$y (lx,ly $stop[$i+3], $stop[$i+4])\n" if $self->{debug} > 1;
	  }
        elsif ($self->{debug} > 1) {
          print STDERR "#  Reached stop position $x,$y\n";
          }
        last STEP;
        }
      } # end test for stop postion(s)

    $self->_croak("On of '$x,$y' is not defined")
      unless defined $x && defined $y;
      
    # get list of potential positions we need to explore from the current one
    my @p = $self->_astar_near_nodes($x,$y, $cells, $closed, $min_x, $min_y, $max_x, $max_y);

    my $n = 0;
    while ($n < scalar @p)
      {
      my $nx = $p[$n]; my $ny = $p[$n+1]; $n += 2;

      if (!defined $nx || !defined $ny)
        {
        require Carp;
        Carp::confess("On of '$nx,$ny' is not defined");
        }
      my $lg = $g;
      $lg += _astar_modifier($px,$py,$x,$y,$nx,$ny,$cells) if defined $px && defined $py;

      my $n = "$nx,$ny";

      # was already open?
      next if (exists $open_by_pos->{$n});

#      print STDERR "#   Already open pos $nx,$ny with $open_by_pos->{$n} (would be $lg)\n"
#	 if $self->{debug} && exists $open_by_pos->{$n};
#
#      next if exists $open_by_pos->{$n} && $open_by_pos->{$n} <= $lg; 
#
#      if (exists $open_by_pos->{$n})
#        {
#        $open->delete($nx, $ny);
#        }

      # calculate distance to each possible stop position, and
      # use the lowest one
      my $lowest_distance = _astar_distance($nx, $ny, $stop[0], $stop[1]);
      for (my $i = $per_field; $i < $stop; $i += $per_field)
        {
        my $d = _astar_distance($nx, $ny, $stop[$i], $stop[$i+1]);
        $lowest_distance = $d if $d < $lowest_distance; 
        }

      print STDERR "#   Opening pos $nx,$ny ($lowest_distance + $lg)\n" if $self->{debug} > 1;

      # open new position into OPEN
      $open->add( [ $lowest_distance + $lg, $nx, $ny, $x, $y, undef ] );
      $open_by_pos->{$n} = $lg;
      }
    }

  ###########################################################################
  # A* is done, now build a path from the information we computed above:

  # count how many steps we did in A*
  $self->{stats}->{astar_steps} += $tries;

  # no more nodes to follow, so we couldn't find a path
  if (!defined $elem)
    {
    print STDERR "# A* couldn't find a path after $max_tries steps.\n" if $self->{debug};
    return [];
    }

  my $path = [];
  my ($cx,$cy) = ($elem->[1],$elem->[2]);
  # the "last" cell in the path. Since we follow it backwards, it
  # becomes actually the next cell
  my ($lx,$ly);
  my $type;

  my $label_cell = 0;		# found a cell to attach the label to?

  my @bends;			# record all bends in the path to straighten it out

  my $idx = 0;
  # follow $elem back to the source to find the path
  while (defined $cx)
    {
    last unless exists $closed->{"$cx,$cy"};
    my $xy = "$cx,$cy";

    $type = $closed->{$xy}->[ 4 ];

    my ($px,$py) = @{ $closed->{$xy} };		# get X,Y of parent cell

    my $edge_type = ($type||0) & EDGE_TYPE_MASK;
    if ($edge_type == 0)
      {
      my $edge_flags = ($type||0) & EDGE_FLAG_MASK;

      # either a start or a stop cell
      if (!defined $px)
	{
	# We can figure it out from the flag of the position of cx,cy
	#        ................
	#         : EDGE_START_S :
	# .......................................
	# START_E :    px,py     : EDGE_START_W :
	# .......................................
	#         : EDGE_START_N :
	#         ................
	($px,$py) = ($cx, $cy);		# start with same cell
	$py ++ if ($edge_flags & EDGE_START_S) != 0; 
	$py -- if ($edge_flags & EDGE_START_N) != 0; 

	$px ++ if ($edge_flags & EDGE_START_E) != 0; 
	$px -- if ($edge_flags & EDGE_START_W) != 0; 
	}

      # if lx, ly is undefined because px,py is a joint, get it via the stored
      # x,y pos of the very last cell in the path
      if (!defined $lx)
     	{ 
	$lx = $closed->{$xy}->[6];
	$ly = $closed->{$xy}->[7];
	}

      # still not known?
      if (!defined $lx)
	{

	# If lx,ly is undefined because we are at the end of the path,
   	# we can figure out from the flag of the position of cx,cy.
	#       ..............
	#       : EDGE_END_S :
	# .................................
	# END_E :    lx,ly   : EDGE_END_W :
	# .................................
	#       : EDGE_END_N :
	#       ..............
	($lx,$ly) = ($cx, $cy);		# start with same cell

	$ly ++ if ($edge_flags & EDGE_END_S) != 0; 
	$ly -- if ($edge_flags & EDGE_END_N) != 0; 

	$lx ++ if ($edge_flags & EDGE_END_E) != 0; 
	$lx -- if ($edge_flags & EDGE_END_W) != 0; 
	}

      # now figure out correct type for this cell from positions of
      # parent/following cell
      $type += _astar_edge_type($px, $py, $cx, $cy, $lx,$ly);
      }

    print STDERR "#  Following back from $lx,$ly over $cx,$cy to $px,$py\n" if $self->{debug} > 1;

    if ($px == $lx && $py == $ly && ($cx != $lx || $cy != $ly))
      {
      print STDERR 
       "# Warning: A* detected loop in path-backtracking at $px,$py, $cx,$cy, $lx,$ly\n"
       if $self->{debug};
      last;
      }

    $type = EDGE_HOR if ($type & EDGE_TYPE_MASK) == 0;		# last resort

    # if this is the first hor edge, attach the label to it
    # XXX TODO: This clearly is not optimal. Look for left-most HOR CELL
    my $t = $type & EDGE_TYPE_MASK;

    # Do not put the label on crossings:
    if ($label_cell == 0 && (!exists $cells->{"$cx,$cy"}) && ($t == EDGE_HOR || $t == EDGE_VER))
      {
      $label_cell++;
      $type += EDGE_LABEL_CELL;
      }

    push @bends, [ $type, $cx, $cy, -$idx ]
	if ($type == EDGE_S_E || $t == EDGE_S_W || $t == EDGE_N_E || $t == EDGE_N_W);

    unshift @$path, $cx, $cy, $type;		# unshift to reverse the path

    last if $closed->{"$cx,$cy"}->[ 5 ];	# stop here?

    ($lx,$ly) = ($cx,$cy);
    ($cx,$cy) = @{ $closed->{"$cx,$cy"} };	# get X,Y of next cell

    $idx += 3;					# index into $path (for bends)
    }

  print STDERR "# Trying to straighten path\n" if @bends >= 3 && $self->{debug};

  # try to straighten unnec. inward bends
  $self->_straighten_path($path, \@bends, $edge) if @bends >= 3;

  return ($path,$closed,$open_by_pos) if wantarray;
  $path;
  }

  # 1:
  #           |             |
  #      +----+   =>        |
  #      |                  |
  #  ----+            ------+

  # 2:
  #      +---         +------
  #      |            |
  #  +---+        =>  |
  #  |                |

  # 3:
  #  ----+            ------+
  #      |        =>        |
  #      +----+             |
  #           |             |

  # 4:
  #  |                |
  #  +---+            |
  #      |        =>  |
  #      +----+       +------

my $bend_patterns = [

  # The patterns are duplicated to catch both directions of the path:

  # First five entries must match
  #				 dx, dy,
  #				        coordinates for new edge
  #				        (2 == y, 1 == x, first is
  #				        taken from A, second from B)
  # 						  these replace the first & last bend
  # 1:
  [ EDGE_N_W, EDGE_S_E, EDGE_N_W, 0, -1, 2, 1, EDGE_HOR, EDGE_VER, 1,0,  0,-1 ],	# 0
  [ EDGE_N_W, EDGE_S_E, EDGE_N_W, -1, 0, 1, 2, EDGE_VER, EDGE_HOR, 0,1,  -1,0 ],	# 1

  # 2:
  [ EDGE_S_E, EDGE_N_W, EDGE_S_E, 0, -1, 1, 2, EDGE_VER, EDGE_HOR, 0,-1, 1,0 ],		# 2
  [ EDGE_S_E, EDGE_N_W, EDGE_S_E, -1, 0, 2, 1, EDGE_HOR, EDGE_VER, -1,0, 0,1 ],		# 3

  # 3:
  [ EDGE_S_W, EDGE_N_E, EDGE_S_W, 0,  1, 2, 1, EDGE_HOR, EDGE_VER, 1,0, 0,1 ],		# 4
  [ EDGE_S_W, EDGE_N_E, EDGE_S_W, -1, 0, 1, 2, EDGE_VER, EDGE_HOR, 0,-1, -1,0 ],	# 5

  # 4:
  [ EDGE_N_E, EDGE_S_W, EDGE_N_E, 1,  0, 1, 2, EDGE_VER, EDGE_HOR, 0,1, 1,0 ],		# 6
  [ EDGE_N_E, EDGE_S_W, EDGE_N_E, 0, -1, 2, 1, EDGE_HOR, EDGE_VER, -1,0, 0,-1 ],	# 7

  ];

sub _straighten_path
  {
  my ($self, $path, $bends, $edge) = @_;

  # XXX TODO:
  # in case of multiple bends, removes only one of them due to overlap

  my $cells = $self->{cells};

  my $i = 0;
  BEND:
  while ($i < (scalar @$bends - 2))
    {
    # for each bend, check it and the next two bends

#   print STDERR "Checking bend $i at $bends->[$i], $bends->[$i+1], $bends->[$i+2]\n";

    my ($a,$b,$c) = ($bends->[$i],
		     $bends->[$i+1],
		     $bends->[$i+2]);

    my $dx = ($b->[1] - $a->[1]);
    my $dy = ($b->[2] - $a->[2]);

    my $p = 0;
    for my $pattern (@$bend_patterns)
      {
      $p++;
      next if ($a->[0] != $pattern->[0]) ||
	      ($b->[0] != $pattern->[1]) ||
	      ($c->[0] != $pattern->[2]) ||
	      ($dx != $pattern->[3]) ||
	      ($dy != $pattern->[4]);

      # pattern matched
#      print STDERR "# Got bends for pattern ", $p-1," (@$pattern):\n";
#      print STDERR "# type x,y,\n# @$a\n# @$b\n# @$c\n";

      # check that the alternative path is empty

      # new corner:
      my $cx = $a->[$pattern->[5]];
      my $cy = $c->[$pattern->[6]];
      ($cx,$cy) = ($cy,$cx) if $pattern->[5] == 2;	# need to swap?

      next BEND if exists $cells->{"$cx,$cy"};

#      print STDERR "# new corner at $cx,$cy (swap: $pattern->[5])\n";

      # check from A to new corner
      my $x = $a->[1];
      my $y = $a->[2];

      my @replace = ();
      push @replace, $cx, $cy, $pattern->[0] if ($x == $cx && $y == $cy);

      my $ddx = $pattern->[9];
      my $ddy = $pattern->[10];
#      print STDERR "# dx,dy: $ddx,$ddy\n";
      while ($x != $cx || $y != $cy)
	{
	next BEND if exists $cells->{"$x,$y"};
#        print STDERR "# at $x $y (go to $cx,$cy)\n"; sleep(1);
	push @replace, $x, $y, $pattern->[7];
	$x += $ddx;
	$y += $ddy;
	}

      $x = $cx; $y = $cy;

      # check from new corner to C
      $ddx = $pattern->[11];
      $ddy = $pattern->[12];
      while ($x != $c->[1] || $y != $c->[2])
	{
	next BEND if exists $cells->{"$x,$y"};
#        print STDERR "# at $x $y (go to $cx,$cy)\n"; sleep(1);
	push @replace, $x, $y, $pattern->[8];
	
	# set the correct type on the corner
	$replace[-1] = $pattern->[0] if ($x == $cx && $y == $cy);
	$x += $ddx;
	$y += $ddy;
        }
      # insert Corner
      push @replace, $x, $y, $pattern->[8];

#	use Data::Dumper; print STDERR Dumper(@replace);
#	print STDERR "# generated ", scalar @replace, " entries\n";
#	print STDERR "# idx A $a->[3] C $c->[3]\n";

      # the path is clear, so replace the inward bend with the new one
      my $diff = $a->[3] - $c->[3] ? -3 : 3;

      my $idx = 0; my $p_idx = $a->[3] + $diff;
      while ($idx < @replace)
	{
#	 print STDERR "# replace $p_idx .. $p_idx + 2\n";
#	 print STDERR "# replace $path->[$p_idx] with $replace[$idx]\n";
#	 print STDERR "# replace $path->[$p_idx+1] with $replace[$idx+1]\n";
#	 print STDERR "# replace $path->[$p_idx+2] with $replace[$idx+2]\n";

	$path->[$p_idx] = $replace[$idx];
	$path->[$p_idx+1] = $replace[$idx+1];
	$path->[$p_idx+2] = $replace[$idx+2];
	$p_idx += $diff;
	$idx += 3;
 	}
      } # end for this pattern

    } continue { $i++; };
  }

sub _map_as_html
  {
  my ($self, $cells, $p, $closed, $open, $w, $h) = @_;

  $w ||= 20;
  $h ||= 20;

  my $html = <<EOF
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
 <head>
 <style type="text/css">
 <!--
 td {
   background: #a0a0a0;
   border: #606060 solid 1px;
   font-size: 0.75em;
 }
 td.b, td.b, td.c {
   background: #404040;
   border: #606060 solid 1px;
   }
 td.c {
   background: #ffffff;
   }
 table.map {
   border-collapse: collapse;
   border: black solid 1px;
 }
 -->
 </style>
</head>
<body>

<h1>A* Map</h1>

<p>
Nodes examined: <b>##closed##</b> <br>
Nodes still to do (open): <b>##open##</b> <br>
Nodes in path: <b>##path##</b>
</p>
EOF
;

  $html =~ s/##closed##/keys %$closed /eg;
  $html =~ s/##open##/keys %$open /eg;
  my $path = {};
  while (@$p)
    {
    my $x = shift @$p;
    my $y = shift @$p;
    my $t = shift @$p;
    $path->{"$x,$y"} = undef;
    }
  $html =~ s/##path##/keys %$path /eg;
  $html .= '<table class="map">' . "\n";

  for my $y (0..$h)
    {
    $html .= " <tr>\n";
    for my $x (0..$w)
      {
      my $xy = "$x,$y";
      my $c = '&nbsp;' x 4;
      $html .= "  <td class='c'>$c</td>\n" and next if
        exists $cells->{$xy} and ref($cells->{$xy}) =~ /Node/;
      $html .= "  <td class='b'>$c</td>\n" and next if
        exists $cells->{$xy} && !exists $path->{$xy};

      $html .= "  <td>$c</td>\n" and next unless
        exists $closed->{$xy} ||
        exists $open->{$xy};

      my $clr = '#a0a0a0';
      if (exists $closed->{$xy})
        {
        $c =  ($closed->{$xy}->[3] || '0') . '+' . ($closed->{$xy}->[2] || '0');
        my $color = 0x10 + 8 * (($closed->{$xy}->[2] || 0));
        my $color2 = 0x10 + 8 * (($closed->{$xy}->[3] || 0));
        $clr = sprintf("%02x%02x",$color,$color2) . 'a0';
        }
      elsif (exists $open->{$xy})
        {
        $c = '&nbsp;' . $open->{$xy} || '0';
        my $color = 0xff - 8 * ($open->{$xy} || 0);
        $clr = 'a0' . sprintf("%02x",$color) . '00';
        }
      my $b = '';
      $b = 'border: 2px white solid;' if exists $path->{$xy};
      $html .= "  <td style='background: #$clr;$b'>$c</td>\n";
      }
    $html .= " </tr>\n";
    }
 
  $html .= "\n</table>\n";

  $html;
  }
 
1;
__END__

=head1 NAME

Graph::Easy::Layout::Scout - Find paths in a Manhattan-style grid

=head1 SYNOPSIS

	use Graph::Easy;
	
	my $graph = Graph::Easy->new();

	my $bonn = Graph::Easy::Node->new(
		name => 'Bonn',
	);
	my $berlin = Graph::Easy::Node->new(
		name => 'Berlin',
	);

	$graph->add_edge ($bonn, $berlin);

	$graph->layout();

	print $graph->as_ascii( );

	# prints:

	# +------+     +--------+
	# | Bonn | --> | Berlin |
	# +------+     +--------+

=head1 DESCRIPTION

C<Graph::Easy::Layout::Scout> contains just the actual pathfinding code for
L<Graph::Easy|Graph::Easy>. It should not be used directly.

=head1 EXPORT

Exports nothing.

=head1 METHODS

This package inserts a few methods into C<Graph::Easy> and
C<Graph::Easy::Node> to enable path-finding for graphs. It should not
be used directly.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2007 by Tels L<http://bloodgate.com>.

See the LICENSE file for information.

=cut

#############################################################################
# Parse text definition into a Graph::Easy object
#
#############################################################################

package Graph::Easy::Parser;

use Graph::Easy;

$VERSION = '0.35';
use Graph::Easy::Base;
@ISA = qw/Graph::Easy::Base/;
use Scalar::Util qw/weaken/;

use strict;
use constant NO_MULTIPLES => 1;

sub _init
  {
  my ($self,$args) = @_;

  $self->{error} = '';
  $self->{debug} = 0;
  $self->{fatal_errors} = 1;
  
  foreach my $k (keys %$args)
    {
    if ($k !~ /^(debug|fatal_errors)\z/)
      {
      require Carp;
      my $class = ref($self);
      Carp::confess ("Invalid argument '$k' passed to $class" . '->new()');
      }
    $self->{$k} = $args->{$k};
    }

  # what to replace the matched text with
  $self->{replace} = '';
  $self->{attr_sep} = ':';
  # An optional regexp to remove parts of an autosplit label, used by Graphviz
  # to remove " <p1> ":
  $self->{_qr_part_clean} = undef;

  # setup default class names for generated objects
  $self->{use_class} = {
    edge  => 'Graph::Easy::Edge',
    group => 'Graph::Easy::Group',
    graph => 'Graph::Easy',
    node  => 'Graph::Easy::Node',
  };

  $self;
  }

sub reset
  {
  # reset the status of the parser, clear errors etc.
  my $self = shift;

  $self->{error} = '';
  $self->{anon_id} = 0;
  $self->{cluster_id} = '';		# each cluster gets a unique ID
  $self->{line_nr} = -1;
  $self->{match_stack} = [];		# patterns and their handlers

  $self->{clusters} = {};		# cluster names we already created

  Graph::Easy::Base::_reset_id();	# start with the same set of IDs
  
  # After "[ 1 ] -> [ 2 ]" we push "2" on the stack and when we encounter
  # " -> [ 3 ]" treat the stack as a node-list left of "3".
  # In addition, for " [ 1 ], [ 2 ] => [ 3 ]", the stack will contain
  # "1" and "2" when we encounter "3".
  $self->{stack} = [];

  $self->{group_stack} = [];	# all the (nested) groups we are currently in
  $self->{left_stack} = [];	# stack for the left side for "[]->[],[],..."
  $self->{left_edge} = undef;	# for -> [A], [B] continuations

  Graph::Easy->_drop_special_attributes();

  $self->{_graph} = $self->{use_class}->{graph}->new( {
      debug => $self->{debug},
      strict => 0,
      fatal_errors => $self->{fatal_errors},
    } );

  $self;
  }

sub from_file
  {
  # read in entire file and call from_text() on the contents
  my ($self,$file) = @_;

  $self = $self->new() unless ref $self;

  my $doc;
  local $/ = undef;			# slurp mode
  # if given a reference, assume it is a glob, or something like that
  if (ref($file))
    {
    binmode $file, ':utf8' or die ("binmode '$file', ':utf8' failed: $!");
    $doc = <$file>;
    }
  else
    {
    open my $PARSER_FILE, $file or die (ref($self).": Cannot read $file: $!");
    binmode $PARSER_FILE, ':utf8' or die ("binmode '$file', ':utf8' failed: $!");
    $doc = <$PARSER_FILE>;		# read entire file
    close $PARSER_FILE;
    }

  $self->from_text($doc);
  }

sub use_class
  {
  # use the provided class for generating objects of the type $object
  my ($self, $object, $class) = @_;

  $self->_croak("Expected one of node, edge, group or graph, but got $object")
    unless $object =~ /^(node|group|graph|edge)\z/;

  $self->{use_class}->{$object} = $class;

  $self;  
  }

sub _register_handler
  {
  # register a pattern and a handler for it
  my $self = shift;

  push @{$self->{match_stack}}, [ @_ ];

  $self;
  }

sub _register_attribute_handler
  {
  # register a handler for attributes like "{ color: red; }"
  my ($self, $qr_attr, $target) = @_;

  # $object is either undef (for Graph::Easy, meaning "node", or "parent" for Graphviz)

  # { attributes }
  $self->_register_handler( qr/^$qr_attr/,
    sub
      {
      my $self = shift;
      # This happens in the case of "[ Test ]\n { ... }", the node is consumed
      # first, and the attributes are left over:

      my $stack = $self->{stack}; $stack = $self->{group_stack} if @{$self->{stack}} == 0;

      my $object = $target;
      if ($target && $target eq 'parent')
        {
        # for Graphviz, stray attributes always apply to the parent
        $stack = $self->{group_stack};

        $object = $stack->[-1] if ref $stack;
        if (!defined $object)
          {
          # try the scope stack next:
          $stack = $self->{scope_stack};
	  $object = $self->{_graph};
          if (!$stack || @$stack <= 1)
	    {
	    $object = $self->{_graph};
	    $stack = [ $self->{_graph} ];
	    }
          }
        }
      my ($a, $max_idx) = $self->_parse_attributes($1||'', $object);
      return undef if $self->{error};	# wrong attributes or empty stack?

      if (ref($stack->[-1]) eq 'HASH')
	{
	# stack is a scope stack
	# XXX TODO: Find out wether the attribute goes to graph, node or edge
	for my $k (keys %$a)
	  {
	  $stack->[-1]->{graph}->{$k} = $a->{$k};
	  }
	return 1;
	}

      print STDERR "max_idx = $max_idx, stack contains ", join (" , ", @$stack),"\n"
	if $self->{debug} && $self->{debug} > 1;
      if ($max_idx != 1)
	{
	my $i = 0;
        for my $n (@$stack)
	  {
	  $n->set_attributes($a, $i++);
	  }
	}
      else
	{
        # set attributes on all nodes/groups on stack
        for my $n (@$stack) { $n->set_attributes($a); }
	}
      # This happens in the case of "[ a | b ]\n { ... }", the node is consumed
      # first, and the attributes are left over. And if we encounter a basename
      # attribute here, the node-parts will already have been created with the
      # wrong basename, so correct this:
      if (defined $a->{basename})
        {
        for my $s (@$stack)
          {
          # for every node on the stack that is the primary one
          $self->_set_new_basename($s, $a->{basename}) if exists $s->{autosplit_parts};
          }
        }
      1;
      } );
  }

sub _register_node_attribute_handler
  {
  # register a handler for attributes like "[ A ] { ... }"
  my ($self, $qr_node, $qr_oatr) = @_;

  $self->_register_handler( qr/^$qr_node$qr_oatr/,
    sub
      {
      my $self = shift;
      my $n1 = $1;
      my $a1 = $self->_parse_attributes($2||'');
      return undef if $self->{error};
 
      $self->{stack} = [ $self->_new_node ($self->{_graph}, $n1, $self->{group_stack}, $a1) ];

      # forget left stack
      $self->{left_edge} = undef;
      $self->{left_stack} = [];
      1;
      } );
  }

sub _new_group
  {
  # create a new (possible anonymous) group
  my ($self, $name) = @_;

  $name = '' unless defined $name;

  my $gr = $self->{use_class}->{group};

  my $group;

  if ($name eq '')
    {
    print STDERR "# Creating new anon group.\n" if $self->{debug};
    $gr .= '::Anon';
    $group = $gr->new();
    }
  else
    {
    $name = $self->_unquote($name);
    print STDERR "# Creating new group '$name'.\n" if $self->{debug};
    $group = $gr->new( name => $name );
    }

  $self->{_graph}->add_group($group);

  my $group_stack = $self->{group_stack};
  if (@$group_stack > 0)
    {
    $group->set_attribute('group', $group_stack->[-1]->{name});
    }

  $group;
  }

sub _add_group_match
  {
  # register two handlers for group start/end
  my $self = shift;

  my $qr_group_start = $self->_match_group_start();
  my $qr_group_end   = $self->_match_group_end();
  my $qr_oatr  = $self->_match_optional_attributes();

  # "( group start [" or empty group like "( Group )"
  $self->_register_handler( qr/^$qr_group_start/,
    sub
      {
      my $self = shift;
      my $graph = $self->{_graph};

      my $end = $2; $end = '' unless defined $end;

      # repair the start of the next node/group
      $self->{replace} = '[' if $end eq '[';
      $self->{replace} = '(' if $end eq '(';

      # create the new group
      my $group = $self->_new_group($1);

      if ($end eq ')')
        {
        # we matched an empty group like "()", or "( group name )"
        $self->{stack} = [ $group ]; 
         print STDERR "# Seen end of group '$group->{name}'.\n" if $self->{debug};
        }
      else
        {
	# only put the group on the stack if it is still open
        push @{$self->{group_stack}}, $group;
        }

      1;
      } );

  # ") { }" # group end (with optional attributes)
  $self->_register_handler( qr/^$qr_group_end$qr_oatr/,
    sub
      {
      my $self = shift;

      my $group = pop @{$self->{group_stack}};
      return $self->parse_error(0) if !defined $group;

      print STDERR "# Seen end of group '$group->{name}'.\n" if $self->{debug};

      my $a1 = $self->_parse_attributes($1||'', 'group', NO_MULTIPLES);
      return undef if $self->{error};

      $group->set_attributes($a1);

      # the new left side is the group itself
      $self->{stack} = [ $group ];
      1;
      } );

  }

sub _build_match_stack
  {
  # put all known patterns and their handlers on the match stack
  my $self = shift;

  # regexps for the different parts
  my $qr_node  = $self->_match_node();
  my $qr_attr  = $self->_match_attributes();
  my $qr_oatr  = $self->_match_optional_attributes();
  my $qr_edge  = $self->_match_edge();
  my $qr_comma = $self->_match_comma();
  my $qr_class = $self->_match_class_selector();

  my $e = $self->{use_class}->{edge};

  # node { color: red; } 
  # node.graph { ... }
  # .foo { ... }
  # .foo, node, edge.red { ... }
  $self->_register_handler( qr/^\s*$qr_class$qr_attr/,
    sub
      {
      my $self = shift;
      my $class = lc($1 || '');
      my $att = $self->_parse_attributes($2 || '', $class, NO_MULTIPLES );

      return undef unless defined $att;		# error in attributes?

      my $graph = $self->{_graph};
      $graph->set_attributes ( $class, $att);

      # forget stacks
      $self->{stack} = [];
      $self->{left_edge} = undef;
      $self->{left_stack} = [];
      1;
      } );

  $self->_add_group_match();

  $self->_register_attribute_handler($qr_attr);
  $self->_register_node_attribute_handler($qr_node,$qr_oatr);

  # , [ Berlin ] { color: red; }
  $self->_register_handler( qr/^$qr_comma$qr_node$qr_oatr/,
    sub
      {
      my $self = shift;
      my $graph = $self->{_graph};
      my $n1 = $1;
      my $a1 = $self->_parse_attributes($2||'');
      return undef if $self->{error};

      push @{$self->{stack}}, 
        $self->_new_node ($graph, $n1, $self->{group_stack}, $a1, $self->{stack});

      if (defined $self->{left_edge})
	{
	my ($style, $edge_label, $edge_atr, $edge_bd, $edge_un) = @{$self->{left_edge}};

	foreach my $node (@{$self->{left_stack}})
          {
	  my $edge = $e->new( { style => $style, name => $edge_label } );
	  $edge->set_attributes($edge_atr);
	  # "<--->": bidirectional
	  $edge->bidirectional(1) if $edge_bd;
	  $edge->undirected(1) if $edge_un;
	  $graph->add_edge ( $node, $self->{stack}->[-1], $edge );
          }
	}
      1;
      } );

  # Things like "[ Node ]" will be consumed before, so we do not need a case
  # for "[ A ] -> [ B ]":
  # node chain continued like "-> { ... } [ Kassel ] { ... }"
  $self->_register_handler( qr/^$qr_edge$qr_oatr$qr_node$qr_oatr/,
    sub
      {
      my $self = shift;

      return if @{$self->{stack}} == 0;	# only match this if stack non-empty

      my $graph = $self->{_graph};
      my $eg = $1;					# entire edge ("-- label -->" etc)

      my $edge_bd = $2 || $4;				# bidirectional edge ('<') ?
      my $edge_un = 0;					# undirected edge?
      $edge_un = 1 if !defined $2 && !defined $5;

      # optional edge label
      my $edge_label = $7;
      my $ed = $3 || $5 || $1;				# edge pattern/style ("--")

      my $edge_atr = $11 || '';				# save edge attributes

      my $n = $12;					# node name
      my $a1 = $self->_parse_attributes($13||'');	# node attributes

      $edge_atr = $self->_parse_attributes($edge_atr, 'edge');
      return undef if $self->{error};

      # allow undefined edge labels for setting them from the class
      # strip trailing spaces and convert \[ => [
      $edge_label = $self->_unquote($edge_label) if defined $edge_label;
      # strip trailing spaces
      $edge_label =~ s/\s+\z// if defined $edge_label;

      # the right side node(s) (multiple in case of autosplit)
      my $nodes_b = [ $self->_new_node ($self->{_graph}, $n, $self->{group_stack}, $a1) ];

      my $style = $self->_link_lists( $self->{stack}, $nodes_b,
	$ed, $edge_label, $edge_atr, $edge_bd, $edge_un);

      # remember the left side
      $self->{left_edge} = [ $style, $edge_label, $edge_atr, $edge_bd, $edge_un ];
      $self->{left_stack} = $self->{stack};

      # forget stack and remember the right side instead
      $self->{stack} = $nodes_b;
      1;
      } );

  my $qr_group_start = $self->_match_group_start();

  # Things like ")" will be consumed before, so we do not need a case
  # for ") -> { ... } ( Group [ B ]":
  # edge to a group like "-> { ... } ( Group ["
  $self->_register_handler( qr/^$qr_edge$qr_oatr$qr_group_start/,
    sub
      {
      my $self = shift;

      return if @{$self->{stack}} == 0;	# only match this if stack non-empty

      my $eg = $1;					# entire edge ("-- label -->" etc)

      my $edge_bd = $2 || $4;				# bidirectional edge ('<') ?
      my $edge_un = 0;					# undirected edge?
      $edge_un = 1 if !defined $2 && !defined $5;

      # optional edge label
      my $edge_label = $7;
      my $ed = $3 || $5 || $1;				# edge pattern/style ("--")

      my $edge_atr = $11 || '';				# save edge attributes

      my $gn = $12; 
      # matched "-> ( Group [" or "-> ( Group ("
      $self->{replace} = '[' if defined $13 && $13 eq '[';
      $self->{replace} = '(' if defined $13 && $13 eq '(';

      $edge_atr = $self->_parse_attributes($edge_atr, 'edge');
      return undef if $self->{error};

      # get the last group of the stack, lest the new one gets nested in it
      pop @{$self->{group_stack}};

      $self->{group_stack} = [ $self->_new_group($gn) ];

      # allow undefined edge labels for setting them from the class
      $edge_label = $self->_unquote($edge_label) if $edge_label;
      # strip trailing spaces
      $edge_label =~ s/\s+\z// if $edge_label;

      my $style = $self->_link_lists( $self->{stack}, $self->{group_stack},
	$ed, $edge_label, $edge_atr, $edge_bd, $edge_un);

      # remember the left side
      $self->{left_edge} = [ $style, $edge_label, $edge_atr, $edge_bd, $edge_un ];
      $self->{left_stack} = $self->{stack};
      # forget stack
      $self->{stack} = [];
      # matched "->()" so remember the group on the stack
      $self->{stack} = [ $self->{group_stack}->[-1] ] if defined $13 && $13 eq ')';

      1;
      } );
  }

sub _line_insert
  {
  # what to insert between two lines, '' for Graph::Easy, ' ' for Graphviz;
  '';
  }

sub _clean_line
  { 
  # do some cleanups on a line before handling it
  my ($self,$line) = @_;

  chomp($line);

  # convert #808080 into \#808080, and "#fff" into "\#fff"
  my $sep = $self->{attr_sep};
  $line =~ s/$sep\s*("?)(#(?:[a-fA-F0-9]{6}|[a-fA-F0-9]{3}))("?)/$sep $1\\$2$3/g;

  # remove comment at end of line (but leave \# alone):
  $line =~ s/(:[^\\]|)$self->{qr_comment}.*/$1/;

  # remove white space at end (but not at the start, to keep "  ||" intact
  $line =~ s/\s+\z//;

#  print STDERR "# at line '$line' stack: ", join(",",@{ $self->{stack}}),"\n";

  $line;
  }

sub from_text
  {
  my ($self,$txt) = @_;

  # matches a multi-line comment
  my $o_cmt = qr#((\s*/\*.*?\*/\s*)*\s*|\s+)#;

  if ((ref($self)||$self) eq 'Graph::Easy::Parser' && 
    # contains "digraph GRAPH {" or something similiar
     ( $txt =~ /^(\s*|\s*\/\*.*?\*\/\s*)(strict)?$o_cmt(di)?graph$o_cmt("[^"]*"|[\w_]+)$o_cmt\{/im ||
    # contains "digraph {" or something similiar	
      $txt =~ /^(\s*|\s*\/\*.*?\*\/\s*)(strict)?${o_cmt}digraph$o_cmt\{/im || 
    # contains "strict graph {" or something similiar	
      $txt =~ /^(\s*|\s*\/\*.*?\*\/\s*)strict${o_cmt}(di)?graph$o_cmt\{/im)) 
    {
    require Graph::Easy::Parser::Graphviz;
    # recreate ourselfes, and pass our arguments along
    my $debug = 0;
    my $old_self = $self;
    if (ref($self))
      {
      $debug = $self->{debug};
      $self->{fatal_errors} = 0;
      }
    $self = Graph::Easy::Parser::Graphviz->new( debug => $debug, fatal_errors => 0 );
    $self->reset();
    $self->{_old_self} = $old_self if ref($self);
    }

  if ((ref($self)||$self) eq 'Graph::Easy::Parser' && 
    # contains "graph: {"
      $txt =~ /^([\s\n\t]*|\s*\/\*.*?\*\/\s*)graph\s*:\s*\{/m) 
    {
    require Graph::Easy::Parser::VCG;
    # recreate ourselfes, and pass our arguments along
    my $debug = 0;
    my $old_self = $self;
    if (ref($self))
      {
      $debug = $self->{debug};
      $self->{fatal_errors} = 0;
      }
    $self = Graph::Easy::Parser::VCG->new( debug => $debug, fatal_errors => 0 );
    $self->reset();
    $self->{_old_self} = $old_self if ref($self);
    }

  $self = $self->new() unless ref $self;
  $self->reset();

  my $graph = $self->{_graph};
  return $graph if !defined $txt || $txt =~ /^\s*\z/;		# empty text?
 
  my $uc = $self->{use_class};

  # instruct the graph to use the custom classes, too
  for my $o (keys %$uc)
    {
    $graph->use_class($o, $uc->{$o}) unless $o eq 'graph';	# group, node and edge
    }

  my @lines = split /(\r\n|\n|\r)/, $txt;

  my $backbuffer = '';	# left over fragments to be combined with next line

  my $qr_comment = $self->_match_commented_line();
  $self->{qr_comment} = $self->_match_comment();
  # cache the value of this since it can be expensive to construct:
  $self->{_match_single_attribute} = $self->_match_single_attribute();

  $self->_build_match_stack();

  ###########################################################################
  # main parsing loop

  my $handled = 0;		# did we handle a fragment?
  my $line;

#  my $counts = {};
  LINE:
  while (@lines > 0 || $backbuffer ne '')
    {
    # only accumulate more text if we didn't handle a fragment
    if (@lines > 0 && $handled == 0)
      {
      $self->{line_nr}++;
      my $curline = shift @lines;

      # discard empty lines, or completely commented out lines
      next if $curline =~ $qr_comment;

      # convert tabs to spaces (the regexps don't expect tabs)
      $curline =~ tr/\t/ /d;

      # combine backbuffer, what to insert between two lines and next line:
      $line = $backbuffer . $self->_line_insert() . $self->_clean_line($curline);
      }

  print STDERR "# Line is '$line'\n" if $self->{debug} && $self->{debug} > 2;
  print STDERR "#  Backbuffer is '$backbuffer'\n" if $self->{debug} && $self->{debug} > 2;

    $handled = 0;
#debug my $count = 0;
    PATTERN:
    for my $entry (@{$self->{match_stack}})
      {
      # nothing to match against?
      last PATTERN if $line eq '';

      $self->{replace} = '';	# as default just remove the matched text
      my ($pattern, $handler, $replace) = @$entry;

  print STDERR "# Matching against $pattern\n" if $self->{debug} && $self->{debug} > 3;

      if ($line =~ $pattern)
        {
#debug $counts->{$count}++;
  print STDERR "# Matched, calling handler\n" if $self->{debug} && $self->{debug} > 2;
        my $rc = 1;
        $rc = &$handler($self) if defined $handler;
        if ($rc)
	  {
          $replace = $self->{replace} unless defined $replace;
	  $replace = &$replace($self,$line) if ref($replace);
  print STDERR "# Handled it successfully.\n" if $self->{debug} && $self->{debug} > 2;
          $line =~ s/$pattern/$replace/;
  print STDERR "# Line is now '$line' (replaced with '$replace')\n" if $self->{debug} && $self->{debug} > 2;
          $handled++; last PATTERN;
          }
        }
#debug $count ++;

      }

#debug    if ($handled == 0) { $counts->{'-1'}++; }
    # couldn't handle that fragement, so accumulate it and try again
    $backbuffer = $line;

    # stop at the very last line
    last LINE if $handled == 0 && @lines == 0;

    # stop at parsing errors
    last LINE if $self->{error};
    }

  $self->error("'$backbuffer' not recognized by " . ref($self)) if $backbuffer ne '';

  # if something was left on the stack, file ended unexpectedly
  $self->parse_error(7) if !$self->{error} && $self->{scope_stack} && @{$self->{scope_stack}} > 0;

  return undef if $self->{error} && $self->{fatal_errors};

#debug  use Data::Dumper; print Dumper($counts);

  print STDERR "# Parsing done.\n" if $graph->{debug};

  # Do final cleanup (for parsing Graphviz)
  $self->_parser_cleanup() if $self->can('_parser_cleanup');
  $graph->_drop_special_attributes();

  # turn on strict checking on returned graph
  $graph->strict(1);
  $graph->fatal_errors(1);

  $graph;
  }

#############################################################################
# internal routines

sub _edge_style
  {
  my ($self, $ed) = @_;

  my $style = undef;			# default is "inherit from class"
  $style = 'double-dash' if $ed =~ /^(= )+\z/; 
  $style = 'double' if $ed =~ /^=+\z/; 
  $style = 'dotted' if $ed =~ /^\.+\z/; 
  $style = 'dashed' if $ed =~ /^(- )+\z/; 
  $style = 'dot-dot-dash' if $ed =~ /^(..-)+\z/; 
  $style = 'dot-dash' if $ed =~ /^(\.-)+\z/; 
  $style = 'wave' if $ed =~ /^\~+\z/; 
  $style = 'bold' if $ed =~ /^#+\z/; 

  $style;
  }

sub _link_lists
  {
  # Given two node lists and an edge style, links each node from list
  # one to list two.
  my ($self, $left, $right, $ed, $label, $edge_atr, $edge_bd, $edge_un) = @_;

  my $graph = $self->{_graph};
 
  my $style = $self->_edge_style($ed);
  my $e = $self->{use_class}->{edge};

  # add edges for all nodes in the left list
  for my $node (@$left)
    {
    for my $node_b (@$right)
      {
      my $edge = $e->new( { style => $style, name => $label } );

      $graph->add_edge ( $node, $node_b, $edge );

      # 'string' => [ 'string' ]
      # [ { hash }, 'string' ] => [ { hash }, 'string' ]
      my $e = $edge_atr; $e = [ $edge_atr ] unless ref($e) eq 'ARRAY';

      for my $a (@$e)
	{
	if (ref $a)
	  {
	  $edge->set_attributes($a);
	  }
	else
	  {
	  # deferred parsing with the object as param:
	  my $out = $self->_parse_attributes($a, $edge);
	  return undef if $self->{error};
	  $edge->set_attributes($out);
	  }
	}

      # "<--->": bidirectional
      $edge->bidirectional(1) if $edge_bd;
      $edge->undirected(1) if $edge_un;
      }
    }

  $style;
  }

sub _unquote_attribute
  {
  my ($self,$name,$value) = @_;

  $self->_unquote($value);
  }

sub _unquote
  {
  my ($self, $name, $no_collapse) = @_;

  $name = '' unless defined $name;

  # unquote special chars
  $name =~ s/\\([\[\(\{\}\]\)#<>\-\.\=])/$1/g;

  # collapse multiple spaces
  $name =~ s/\s+/ /g unless $no_collapse;

  $name;
  }

sub _add_node
  {
  # add a node to the graph, overidable by subclasses
  my ($self, $graph, $name) = @_;

  $graph->add_node($name);		# add unless exists
  }

sub _get_cluster_name
  {
  # create a unique name for an autosplit node
  my ($self, $base_name) = @_;

  # Try to find a unique cluster name in case some one get's creative and names the
  # last part "-1":

  # does work without cluster-id?
  if (exists $self->{clusters}->{$base_name})
    {
    my $g = 1;
    while ($g == 1)
      {
      my $base_try = $base_name; $base_try .= '-' . $self->{cluster_id} if $self->{cluster_id};
      last if !exists $self->{clusters}->{$base_try};
      $self->{cluster_id}++;
      }
    $base_name .= '-' . $self->{cluster_id} if $self->{cluster_id}; $self->{cluster_id}++;
    }

  $self->{clusters}->{$base_name} = undef;	# reserve this name

  $base_name;
  }

sub _set_new_basename
  {
  # when encountering something like:
  #   [ a | b ]
  #   { basename: foo; }
  # the Parser will create two nodes, ab.0 and ab.1, and then later see
  # the "basename: foo". Sowe need to rename the already created nodes
  # due to the changed basename:
  my ($self, $node, $new_basename) = @_;

  # nothing changes?
  return if $node->{autosplit_basename} eq $new_basename;

  my $g = $node->{graph};

  my @parts = @{$node->{autosplit_parts}};
  my $nr = 0;
  for my $part ($node, @parts)
    {
    print STDERR "# Setting new basename $new_basename for node $part->{name}\n"
      if $self->{debug} > 1;

    $part->{autosplit_basename} = $new_basename;
    $part->set_attribute('basename', $new_basename);
  
    # delete it from the list of nodes
    delete $g->{nodes}->{$part->{name}};
    $part->{name} = $new_basename . '.' . $nr; $nr++;
    # and re-insert it with the right name
    $g->{nodes}->{$part->{name}} = $part;

    # we do not need to care for edges here, as they are stored with refs
    # to the nodes and not the node names itself
    }
  }

sub _autosplit_node
  {
  # Takes a node name like "a|b||c" and splits it into "a", "b", and "c".
  # Returns the individual parts.
  my ($self, $graph, $name, $att, $allow_empty) = @_;
 
  # Default is to have empty parts. Graphviz sets this to true;
  $allow_empty = 1 unless defined $allow_empty;

  my @rc;
  my $uc = $self->{use_class};
  my $qr_clean = $self->{_qr_part_clean};

  # build base name: "A|B |C||D" => "ABCD"
  my $base_name = $name; $base_name =~ s/\s*\|\|?\s*//g;

  # use user-provided base name
  $base_name = $att->{basename} if exists $att->{basename};

  # strip trailing/leading spaces on basename
  $base_name =~ s/\s+\z//;
  $base_name =~ s/^\s+//;

  # first one gets: "ABC", second one "ABC.1" and so on
  $base_name = $self->_get_cluster_name($base_name);

  print STDERR "# Parser: Autosplitting node with basename '$base_name'\n" if $graph->{debug};

  my $first_in_row;			# for relative placement of new row
  my $x = 0; my $y = 0; my $idx = 0;
  my $remaining = $name; my $sep; my $last_sep = '';
  my $add = 0;
  while ($remaining ne '')
    {
    # XXX TODO: parsing of "\|" and "|" in one node
    $remaining =~ s/^((\\\||[^\|])*)(\|\|?|\z)//;
    my $part = $1 || ' ';
    $sep = $3;
    my $port_name = '';

    # possible cleanup for this part
    if ($qr_clean)
      {
      $part =~ s/^$qr_clean//; $port_name = $1;
      }

    # fix [|G|] to have one empty part as last part
    if ($add == 0 && $remaining eq '' && $sep =~ /\|\|?/)
      {
      $add++;				# only do it once
      $remaining .= '|' 
      }

    print STDERR "# Parser: Found autosplit part '$part'\n" if $graph->{debug};

    my $class = $uc->{node};
    if ($allow_empty && $part eq ' ')
      {
      # create an empty node with no border
      $class .= "::Empty";
      }
    elsif ($part =~ /^[ ]{2,}\z/)
      {
      # create an empty node with border
      $part = ' ';
      }
    else
      {
      $part =~ s/^\s+//;	# rem spaces at front
      $part =~ s/\s+\z//;	# rem spaces at end
      }

    my $node_name = "$base_name.$idx";

    if ($graph->{debug})
      {
      my $empty = '';
      $empty = ' empty' if $class ne $self->{use_class}->{node};
      print STDERR "# Parser:  Creating$empty autosplit part '$part'\n" if $graph->{debug};
      }

    # if it doesn't exist, add it, otherwise retrieve node object to $node
    if ($class =~ /::Empty/)
      {
      my $node = $graph->node($node_name);
      if (!defined $node)
	{
	# create node object from the correct class
	$node = $class->new($node_name);
        $graph->add_node($node);
	}
      }

    my $node = $graph->add_node($node_name);
    $node->{autosplit_label} = $part;
    # remember these two for Graphviz
    $node->{autosplit_portname} = $port_name;
    $node->{autosplit_basename} = $base_name;

    push @rc, $node;
    if (@rc == 1)
      {
      # for correct as_txt output
      $node->{autosplit} = $name;
      $node->{autosplit} =~ s/\s+\z//;		# strip trailing spaces
      $node->{autosplit} =~ s/^\s+//;		# strip leading spaces
      $node->{autosplit} =~ s/([^\|])\s+\|/$1 \|/g;	# 'foo  |' => 'foo |'
      $node->{autosplit} =~ s/\|\s+([^\|])/\| $1/g;	# '|  foo' => '| foo'
      $node->set_attribute('basename', $att->{basename}) if defined $att->{basename};
      # list of all autosplit parts so as_txt() can find them easily again
      $node->{autosplit_parts} = [ ];
      $first_in_row = $node;
      }
    else
      {
      # second, third etc. get previous as origin
      my ($sx,$sy) = (1,0);
      my $origin = $rc[-2];
      if ($last_sep eq '||')
        {
        ($sx,$sy) = (0,1); $origin = $first_in_row;
        $first_in_row = $node;
        }
      $node->relative_to($origin,$sx,$sy);
      push @{$rc[0]->{autosplit_parts}}, $node;
      weaken @{$rc[0]->{autosplit_parts}}[-1];

      # suppress as_txt output for other parts
      $node->{autosplit} = undef;
      }	
    # nec. for border-collapse
    $node->{autosplit_xy} = "$x,$y";

    $idx++;						# next node ID
    $last_sep = $sep;
    $x++;
    # || starts a new row:
    if ($sep eq '||')
      {
      $x = 0; $y++;
      }
    }  # end for all parts

  @rc;	# return all created nodes
  }

sub _new_node
  {
  # Create a new node unless it doesn't already exist. If the group stack
  # contains entries, the new node appears first in this/these group(s), so
  # add it to these groups. If the newly created node contains "|", we auto
  # split it up into several nodes and cluster these together.
  my ($self, $graph, $name, $group_stack, $att, $stack) = @_;

  print STDERR "# Parser: new node '$name'\n" if $graph->{debug};

  $name = $self->_unquote($name, 'no_collapse');

  my $autosplit;
  my $uc = $self->{use_class};

  my @rc = ();

  if ($name =~ /^\s*\z/)
    {
    print STDERR "# Parser: Creating anon node\n" if $graph->{debug};
    # create a new anon node and add it to the graph
    my $class = $uc->{node} . '::Anon';
    my $node = $class->new();
    @rc = ( $graph->add_node($node) );
    }
  # nodes to be autosplit will be done in a sep. pass for Graphviz
  elsif ((ref($self) eq 'Graph::Easy::Parser') && $name =~ /[^\\]\|/)
    {
    $autosplit = 1;
    @rc = $self->_autosplit_node($graph, $name, $att);
    }
  else
    {
    # strip trailing and leading spaces
    $name =~ s/\s+\z//; 
    $name =~ s/^\s+//; 

    # collapse multiple spaces
    $name =~ s/\s+/ /g;

    # unquote \|
    $name =~ s/\\\|/\|/g;

    if ($self->{debug})
      {
      if (!$graph->node($name))
	{
	print STDERR "# Parser: Creating normal node from name '$name'.\n";
	}
      else
	{
	print STDERR "# Parser: Found node '$name' already in graph.\n";
	}
      }
    @rc = ( $self->_add_node($graph, $name) ); 	# add to graph, unless exists
    }

  $self->parse_error(5) if exists $att->{basename} && !$autosplit;

  my $b = $att->{basename};
  delete $att->{basename};

  # on a node list "[A],[B] { ... }" set attributes on all nodes
  # encountered so far, too:
  if (defined $stack)
    {
    for my $node (@$stack)
      {
      $node->set_attributes ($att, 0);
      }
    }
  my $index = 0;
  my $group = $self->{group_stack}->[-1];

  for my $node (@rc)
    {
    $node->add_to_group($group) if $group;
    $node->set_attributes ($att, $index);
    $index++;
    }
  
  $att->{basename} = $b if defined $b;

  # return list of created nodes (usually one, but more for "A|B")
  @rc;
  }

sub _match_comma
  {
  # return a regexp that matches something like " , " like in:
  # "[ Bonn ], [ Berlin ] => [ Hamburg ]"
  qr/\s*,\s*/;
  }

sub _match_comment
  {
  # match the start of a comment
  qr/(^|[^\\])#/;
  }

sub _match_commented_line
  {
  # match empty lines or a completely commented out line
  qr/^\s*(#|\z)/;
  }

sub _match_attributes
  {
  # return a regexp that matches something like " { color: red; }" and returns
  # the inner text without the {}
  qr/\s*\{\s*([^\}]+?)\s*\}/;
  }

sub _match_optional_attributes
  {
  # return a regexp that matches something like " { color: red; }" and returns
  # the inner text with the {}
  qr/(\s*\{[^\}]+?\})?/;
  }

sub _match_node
  {
  # return a regexp that matches something like " [ bonn ]" and returns
  # the inner text without the [] (might leave some spaces)

  qr/\s*\[				#  '[' start of the node
    (
     (?:				# non-capturing group
      \\.				# either '\]' or '\N' etc.
      |					#  or
      [^\]\\]				# not ']' and not '\'
     )*					# 0 times for '[]'
    )
    \]/x;				# followed by ']'
  }

sub _match_class_selector
  {
  my $class = qr/(?:\.\w+|graph|(?:edge|group|node)(?:\.\w+)?)/;
  qr/($class(?:\s*,\s*$class)*)/;
  }

sub _match_single_attribute
  {
  qr/\s*([^:]+?)\s*:\s*("(?:\\"|[^"])+"|(?:\\;|[^;])+?)(?:\s*;\s*|\s*\z)/;	# "name: value"
  }

sub _match_group_start
  {
  # Return a regexp that matches something like " ( group [" and returns
  # the text between "(" and "[". Also matches empty groups like "( group )"
  # or even "()":
  qr/\s*\(\s*([^\[\)\(]*?)\s*([\[\)\(])/;
  }

sub _match_group_end
  {
  # return a regexp that matches something like " )".
  qr/\s*\)\s*/;
  }

sub _match_edge
  {
  # Matches all possible edge variants like:
  # -->, ---->, ==> etc
  # <-->, <---->, <==>, <..> etc
  # <-- label -->, <.- label .-> etc  
  # -- label -->, .- label .-> etc  

  # "- " must come before "-"!
  # likewise, "..-" must come before ".-" must come before "."

  # XXX TODO: convert the first group into a non-matching group

  qr/\s*
     (					# egde without label ("-->")
       (<?) 				 # optional left "<"
       (=\s|=|-\s|-|\.\.-|\.-|\.|~)+>	 # pattern (style) of edge
     |					# edge with label ("-- label -->")
       (<?) 				 # optional left "<"
       ((=\s|=|-\s|-|\.\.-|\.-|\.|~)+)	 # pattern (style) of edge
       \s+				 # followed by at least a space
       ((?:\\.|[^>\[\{])*?)		 # either \\, \[ etc, or not ">", "[", "{"
       (\s+\5)>				 # a space and pattern before ">"

# inserting this needs mucking with all the code that access $5 etc
#     |					# undirected edge (without arrows, but with label)
#       ((=\s|=|-\s|-|\.\.-|\.-|\.|~)+)	 # pattern (style) of edge
#       \s+				 # followed by at least a space
#       ((?:\\.|[^>\[\{])*?)		 # either \\, \[ etc, or not ">", "[", "{"
#       (\s+\10)				 # a space and pattern

     |					# undirected edge (without arrows and label)
       (\.\.-|\.-)+			 # pattern (style) of edge (at least once)
     |
       (=\s|=|-\s|-|\.|~){2,}		 # these at least two times
     )
     /x;
   }

sub _clean_attributes
  {
  my ($self,$text) = @_;

  $text =~ s/^\s*\{\s*//;	# remove left-over "{" and spaces
  $text =~ s/\s*\}\s*\z//;	# remove left-over "}" and spaces

  $text;
  }

sub _parse_attributes
  {
  # Takes a text like "attribute: value;  attribute2 : value2;" and
  # returns a hash with the attributes. $class defaults to 'node'.
  # In list context, also returns a flag that is maxlevel-1 when one
  # of the attributes was a multiple one (aka 2 for "red|green", 1 for "red");
  my ($self, $text, $object, $no_multiples) = @_;

  my $class = $object;
  $class = $object->{class} if ref($object);
  $class = 'node' unless defined $class;
  $class =~ s/\..*//;				# remove subclass

  my $out;
  my $att = {};
  my $multiples = 0;

  $text = $self->_clean_attributes($text);
  my $qr_att  = $self->{_match_single_attribute};
  my $qr_cmt;  $qr_cmt  = $self->_match_multi_line_comment()
   if $self->can('_match_multi_line_comment');
  my $qr_satt; $qr_satt = $self->_match_special_attribute() 
   if $self->can('_match_special_attribute');

  return {} if $text =~ /^\s*\z/;

  print STDERR "attr parsing: matching\n '$text'\n against $qr_att\n" if $self->{debug} > 3;    

  while ($text ne '')
    {
    print STDERR "attr parsing: matching '$text'\n" if $self->{debug} > 3;    

    # remove a possible comment
    $text =~ s/^$qr_cmt//g if $qr_cmt;

    # if the last part was a comment, we end up with an empty text here:
    last if $text =~ /^\s*\z/;

    # match and remove "name: value"
    my $done = ($text =~ s/^$qr_att//) || 0;

    # match and remove "name" if "name: value;" didn't match
    $done++ if $done == 0 && $qr_satt && ($text =~ s/^$qr_satt//);

    return $self->error ("Error in attribute: '$text' doesn't look valid to me.")
      if $done == 0;

    my $name = $1;
    my $v = $2; $v = '' unless defined $v;	# for special attributes w/o value

    # unquote and store
    $out->{$name} = $self->_unquote_attribute($name,$v);
    }

  if ($self->{debug} && $self->{debug} > 1)
    {
    require Data::Dumper;
    print STDERR "# ", join (" ", caller),"\n";
    print STDERR "# Parsed attributes into:\n", Data::Dumper::Dumper($out),"\n";
    }
  # possible remap attributes (for parsing Graphviz)
  $out = $self->_remap_attributes($out, $object) if $self->can('_remap_attributes');

  my $g = $self->{_graph};
  # check for being valid and finally create hash with name => value pairs
  for my $name (sort keys %$out)
    {
    my ($rc, $newname, $v) = $g->validate_attribute($name,$out->{$name},$class,$no_multiples);

    $self->error($g->{error}) if defined $rc;

    $multiples = scalar @$v if ref($v) eq 'ARRAY';

    $att->{$newname} = $v if defined $v;	# undef => ignore attribute
    }

  return $att unless wantarray;

  ($att, $multiples || 1);
  }

sub parse_error
  {
  # take a msg number, plus params, and throws an exception
  my $self = shift;
  my $msg_nr = shift;

  # XXX TODO: should really use the msg nr mapping
  my $msg = "Found unexpected group end";						# 0
  $msg = "Error in attribute: '##param2##' is not a valid attribute for a ##param3##"	# 1
        if $msg_nr == 1;
  $msg = "Error in attribute: '##param1##' is not a valid ##param2## for a ##param3##"
	if $msg_nr == 2;								# 2
  $msg = "Error: Found attributes, but expected group or node start"
	if $msg_nr == 3;								# 3
  $msg = "Error in attribute: multi-attribute '##param1##' not allowed here"
	if $msg_nr == 4;								# 4
  $msg = "Error in attribute: basename not allowed for non-autosplit nodes"
	if $msg_nr == 5;								# 5
  # for graphviz parsing
  $msg = "Error: Already seen graph start"
	if $msg_nr == 6;								# 6
  $msg = "Error: Expected '}', but found file end"
	if $msg_nr == 7;								# 7

  my $i = 1;
  foreach my $p (@_)
    {
    $msg =~ s/##param$i##/$p/g; $i++;
    }

  $self->error($msg . ' at line ' . $self->{line_nr});
  }

sub _parser_cleanup
  {
  # After initial parsing, do a cleanup pass.
  my ($self) = @_;

  my $g = $self->{_graph};
  
  for my $n (values %{$g->{nodes}})
    {
    next if $n->{autosplit};
    $self->warn("Node '" . $self->_quote($n->{name}) . "' has an offset but no origin")
      if (($n->attribute('offset') ne '0,0') && $n->attribute('origin') eq '');
    }

  $self;
  }

sub _quote
  {
  # make a node name safe for error message output
  my ($self,$n) = @_;

  $n =~ s/'/\\'/g;

  $n;
  }

1;
__END__

=head1 NAME

Graph::Easy::Parser - Parse Graph::Easy from textual description

=head1 SYNOPSIS

        # creating a graph from a textual description
        use Graph::Easy::Parser;
        my $parser = Graph::Easy::Parser->new();

        my $graph = $parser->from_text(
                '[ Bonn ] => [ Berlin ]'.
                '[ Berlin ] => [ Rostock ]'.
        );
        print $graph->as_ascii();

        print $parser->from_file('mygraph.txt')->as_ascii();

	# Also works automatically on graphviz code:
        print Graph::Easy::Parser->from_file('mygraph.dot')->as_ascii();

=head1 DESCRIPTION

C<Graph::Easy::Parser> lets you parse simple textual descriptions
of graphs, and constructs a C<Graph::Easy> object from them.

The resulting object can than be used to layout and output the graph.

=head2 Input

The input consists of text describing the graph, encoded in UTF-8.

Example:

	[ Bonn ]      --> [ Berlin ]
	[ Frankfurt ] <=> [ Dresden ]
	[ Bonn ]      --> [ Frankfurt ]
	[ Bonn ]      = > [ Frankfurt ]

=head3 Graphviz

In addition there is a bit of magic that detects graphviz code, so
input of the following form will also work:

	digraph Graph1 {
		"Bonn" -> "Berlin"
	}

Note that the magic detection only works for B<named> graphs or graph
with "digraph" at their start, so the following will not be detected as
graphviz code because it looks exactly like valid Graph::Easy code
at the start:

	graph {
		"Bonn" -> "Berlin"
	}

See L<Graph::Easy::Parser::Graphviz> for more information about parsing
graphs in the DOT language.

=head3 VCG

In addition there is a bit of magic that detects VCG code, so
input of the following form will also work:

	graph: {
		node: { title: Bonn; }
		node: { title: Berlin; }
		edge: { sourcename: Bonn; targetname: Berlin; }
	}

See L<Graph::Easy::Parser::VCG> for more information about parsing
graphs in the VCG language.

=head2 Input Syntax

This is a B<very> brief description of the syntax for the Graph::Easy
language, for a full specification, please see L<Graph::Easy::Manual>.

=over 2

=item nodes

Nodes are rendered (or "quoted", if you wish) with enclosing square brackets:

	[ Single node ]
	[ Node A ] --> [ Node B ]

Anonymous nodes do not have a name and cannot be refered to again:

	[ ] -> [ Bonn ] -> [ ]

This creates three nodes, two of them anonymous.

=item edges

The edges between the nodes can have the following styles:

	->		solid
	=>		double
	.>		dotted
	~>		wave

	- >		dashed
	.->		dot-dash
	..->		dot-dot-dash
	= >		double-dash

There are also the styles C<bold>, C<wide> and C<broad>. Unlike the others,
these can only be set via the (optional) edge attributes:

	[ AB ] --> { style: bold; } [ ABC ]

You can repeat each of the style-patterns as much as you like:

	--->
	==>
	=>
	~~~~~>
	..-..-..->

Note that in patterns longer than one character, the entire
pattern must be repeated e.g. all characters of the pattern must be
present. Thus:

	..-..-..->	# valid dot-dot-dash
	..-..-..>	# invalid!

	.-.-.->		# valid dot-dash
	.-.->		# invalid!

In additon to the styles, the following two directions are possible:

	 --		edge without arrow heads
	 -->		arrow at target node (end point)
	<-->		arrow on both the source and target node
			(end and start point)

Of course you can combine all directions with all styles. However,
note that edges without arrows cannot use the shortcuts for styles:

	---		# valid
	.-.-		# valid
	.-		# invalid!
	-		# invalid!
	~		# invalid!

Just remember to use at least two repititions of the full pattern
for arrow-less edges.

You can also give edges a label, either by inlining it into the style,
or by setting it via the attributes:

	[ AB ] --> { style: bold; label: foo; } [ ABC ]

	-- foo -->
	... baz ...>

	-- solid -->
	== double ==>
	.. dotted ..>
	~~ wave ~~>

	-  dashed - >
	=  double-dash = >
	.- dot-dash .->
	..- dot-dot-dash ..->

Note that the two patterns on the left and right of the label must be
the same, and that there is a space between the left pattern and the
label, as well as the label and the right pattern.

You may use inline label only with edges that have an arrow. Thus:

	<-- label -->	# valid
	-- label -->	# valid

	-- label --	# invalid!

To use a label with an edge without arrow heads, use the attributes:

	[ AB ] -- { label: edgelabel; } [ CD ]

=item groups

Round brackets are used to group nodes together:

	( Cities:

		[ Bonn ] -> [ Berlin ]
	)

Anonymous groups do not have a name and cannot be refered to again:

	( [ Bonn ] ) -> [ Berlin ]

This creates an anonymous group with the node C<Bonn> in it, and
links it to the node C<Berlin>.

=back

Please see L<Graph::Easy::Manual> for a full description of the syntax rules.

=head2 Output

The output will be a L<Graph::Easy|Graph::Easy> object (unless overrriden
with C<use_class()>), see the documentation for Graph::Easy what you can do
with it.

=head1 EXAMPLES

See L<Graph::Easy> for an extensive list of examples.

=head1 METHODS

C<Graph::Easy::Parser> supports the following methods:

=head2 new()

	use Graph::Easy::Parser;
	my $parser = Graph::Easy::Parser->new();

Creates a new parser object. The valid parameters are:

	debug
	fatal_errors

The first will enable debug output to STDERR:

	my $parser = Graph::Easy::Parser->new( debug => 1 );
	$parser->from_text('[A] -> [ B ]');

Setting C<fatal_errors> to 0 will make parsing errors not die, but
just set an error string, which can be retrieved with L<error()>.

	my $parser = Graph::Easy::Parser->new( fatal_errors => 0 );
	$parser->from_text(' foo ' );
	print $parser->error();

See also L<catch_messages()> for how to catch errors and warnings.

=head2 reset()

	$parser->reset();

Reset the status of the parser, clear errors etc. Automatically called
when you call any of the C<from_XXX()> methods below.

=head2 use_class()

	$parser->use_class('node', 'Graph::Easy::MyNode');

Override the class to be used to constructs objects while parsing. The
first parameter can be one of the following:

	node
	edge
	graph
	group

The second parameter should be a class that is a subclass of the
appropriate base class:

	package Graph::Easy::MyNode;

	use base qw/Graph::Easy::Node/;

	# override here methods for your node class

	######################################################
	# when overriding nodes, we also need ::Anon

	package Graph::Easy::MyNode::Anon;

	use base qw/Graph::Easy::MyNode/;
	use base qw/Graph::Easy::Node::Anon/;

	######################################################
	# and :::Empty

	package Graph::Easy::MyNode::Empty;

	use base qw/Graph::Easy::MyNode/;

	######################################################
	package main;
	
	use Graph::Easy::Parser;
	use Graph::Easy;

	use Graph::Easy::MyNode;
	use Graph::Easy::MyNode::Anon;
	use Graph::Easy::MyNode::Empty;

	my $parser = Graph::Easy::Parser;

	$parser->use_class('node', 'Graph::Easy::MyNode');

	my $graph = $parser->from_text(...);

The object C<$graph> will now contain nodes that are of your
custom class instead of plain C<Graph::Easy::Node>.

When overriding nodes, you also should provide subclasses
for C<Graph::Easy::Node::Anon> and C<Graph::Easy::Node::Empty>,
and make these subclasses of your custom node class as shown
above. For edges, groups and graphs, you need just one subclass.

=head2 from_text()

	my $graph = $parser->from_text( $text );

Create a L<Graph::Easy|Graph::Easy> object from the textual description in C<$text>.

Returns undef for error, you can find out what the error was
with L<error()>.

This method will reset any previous error, and thus the C<$parser> object
can be re-used to parse different texts by just calling C<from_text()>
multiple times.

=head2 from_file()

	my $graph = $parser->from_file( $filename );
	my $graph = Graph::Easy::Parser->from_file( $filename );

Creates a L<Graph::Easy|Graph::Easy> object from the textual description in the file
C<$filename>.

The second calling style will create a temporary C<Graph::Easy::Parser> object,
parse the file and return the resulting C<Graph::Easy> object.

Returns undef for error, you can find out what the error was
with L<error()> when using the first calling style.

=head2 error()

	my $error = $parser->error();

Returns the last error, or the empty string if no error occured.

If you want to catch warnings from the parser, enable catching
of warnings or errors:

	$parser->catch_messages(1);

	# Or individually:
	# $parser->catch_warnings(1);
	# $parser->catch_errors(1);

	# something which warns or throws an error:
	...

	if ($parser->error())
	  {
	  my @errors = $parser->errors();
	  }
	if ($parser->warning())
	  {
	  my @warnings = $parser->warnings();
	  }

See L<Graph::Easy::Base> for more details on error/warning message capture.

=head2 parse_error()

	$parser->parse_error( $msg_nr, @params);

Sets an error message from a message number and replaces embedded
templates like C<##param1##> with the passed parameters.

=head2 _parse_attributes()

	my $attributes = $parser->_parse_attributes( $txt, $class );
	my ($att, $multiples) = $parser->_parse_attributes( $txt, $class );
  
B<Internal usage only>. Takes a text like this:

	attribute: value;  attribute2 : value2;

and returns a hash with the attributes.

In list context, also returns the max count of multiple attributes, e.g.
3 when it encounters something like C<< red|green|blue >>. When

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>. L<Graph::Easy::Parser::Graphviz> and L<Graph::Easy::Parser::VCG>.

=head1 AUTHOR

Copyright (C) 2004 - 2007 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut
#############################################################################
# Parse graphviz/dot text into a Graph::Easy object
#
#############################################################################

package Graph::Easy::Parser::Graphviz;

$VERSION = '0.17';
use Graph::Easy::Parser;
@ISA = qw/Graph::Easy::Parser/;

use strict;
use utf8;
use constant NO_MULTIPLES => 1;

sub _init
  {
  my $self = shift;

  $self->SUPER::_init(@_);
  $self->{attr_sep} = '=';
  # remove " <p1> " from autosplit (shape=record) labels
  $self->{_qr_part_clean} = qr/\s*<([^>]*)>/;

  $self;
  }

sub reset
  {
  my $self = shift;

  $self->SUPER::reset(@_);

  # set some default attributes on the graph object, because graphviz has
  # different defaults as Graph::Easy
  my $g = $self->{_graph};

  $g->set_attribute('colorscheme','x11');
  $g->set_attribute('flow','south');
  $g->set_attribute('edge','arrow-style', 'filled');
  $g->set_attribute('group','align', 'center');
  $g->set_attribute('group','fill', 'inherit');

  $self->{scope_stack} = [];

  # allow some temp. values during parsing
  $g->_allow_special_attributes(
    {
    node => {
      shape => [
       "",
        [ qw/ circle diamond edge ellipse hexagon house invisible
		invhouse invtrapezium invtriangle octagon parallelogram pentagon
		point triangle trapezium septagon rect rounded none img record/ ],
       '',
       '',
       undef,
      ],
    },
    } );

  $g->{_warn_on_unknown_attributes} = 1;

  $self;
  }

# map "&tilde;" to "~" 
my %entities = (
  'amp'    => '&',
  'quot'   => '"',
  'lt'     => '<',
  'gt'     => '>',
  'nbsp'   => ' ',		# this is a non-break-space between '' here!
  'iexcl'  => '¡',
  'cent'   => '¢',
  'pound'  => '£',
  'curren' => '¤',
  'yen'    => '¥',
  'brvbar' => '¦',
  'sect'   => '§',
  'uml'    => '¨',
  'copy'   => '©',
  'ordf'   => 'ª',
  'ordf'   => 'ª',
  'laquo'  => '«',
  'not'    => '¬',
  'shy'    => "\x{00AD}",		# soft-hyphen
  'reg'    => '®',
  'macr'   => '¯',
  'deg'    => '°',
  'plusmn' => '±',
  'sup2'   => '²',
  'sup3'   => '³',
  'acute'  => '´',
  'micro'  => 'µ',
  'para'   => '¶',
  'midot'  => '·',
  'cedil'  => '¸',
  'sup1'   => '¹',
  'ordm'   => 'º',
  'raquo'  => '»',
  'frac14' => '¼',
  'frac12' => '½',
  'frac34' => '¾',
  'iquest' => '¿',
  'Agrave' => 'À',
  'Aacute' => 'Á',
  'Acirc'  => 'Â',
  'Atilde' => 'Ã',
  'Auml'   => 'Ä',
  'Aring'  => 'Å',
  'Aelig'  => 'Æ',
  'Ccedil' => 'Ç',
  'Egrave' => 'È',
  'Eacute' => 'É',
  'Ecirc'  => 'Ê',
  'Euml'   => 'Ë',
  'Igrave' => 'Ì',
  'Iacute' => 'Í',
  'Icirc'  => 'Î',
  'Iuml'   => 'Ï',
  'ETH'    => 'Ð',
  'Ntilde' => 'Ñ',
  'Ograve' => 'Ò',
  'Oacute' => 'Ó',
  'Ocirc'  => 'Ô',
  'Otilde' => 'Õ',
  'Ouml'   => 'Ö',
  'times'  => '×',
  'Oslash' => 'Ø',
  'Ugrave' => 'Ù',
  'Uacute' => 'Ù',
  'Ucirc'  => 'Û',
  'Uuml'   => 'Ü',
  'Yacute' => 'Ý',
  'THORN'  => 'Þ',
  'szlig'  => 'ß',
  'agrave' => 'à',
  'aacute' => 'á',
  'acirc'  => 'â',
  'atilde' => 'ã',
  'auml'   => 'ä',
  'aring'  => 'å',
  'aelig'  => 'æ',
  'ccedil' => 'ç',
  'egrave' => 'è',
  'eacute' => 'é',
  'ecirc'  => 'ê',
  'euml'   => 'ë',
  'igrave' => 'ì',
  'iacute' => 'í',
  'icirc'  => 'î',
  'iuml'   => 'ï',
  'eth'    => 'ð',
  'ntilde' => 'ñ',
  'ograve' => 'ò',
  'oacute' => 'ó',
  'ocirc'  => 'ô',
  'otilde' => 'õ',
  'ouml'   => 'ö',
  'divide' => '÷',
  'oslash' => 'ø',
  'ugrave' => 'ù',
  'uacute' => 'ú',
  'ucirc'  => 'û',
  'uuml'   => 'ü',
  'yacute' => 'ý',
  'thorn'  => 'þ',
  'yuml'   => 'ÿ',
  'Oelig'  => 'Œ',
  'oelig'  => 'œ',
  'Scaron' => 'Š',
  'scaron' => 'š',
  'Yuml'   => 'Ÿ',
  'fnof'   => 'ƒ',
  'circ'   => '^',
  'tilde'  => '~',
  'Alpha'  => 'Α',
  'Beta'   => 'Β',
  'Gamma'  => 'Γ',
  'Delta'  => 'Δ',
  'Epsilon'=> 'Ε',
  'Zeta'   => 'Ζ',
  'Eta'    => 'Η',
  'Theta'  => 'Θ',
  'Iota'   => 'Ι',
  'Kappa'  => 'Κ',
  'Lambda' => 'Λ',
  'Mu'     => 'Μ',
  'Nu'     => 'Ν',
  'Xi'     => 'Ξ',
  'Omicron'=> 'Ο',
  'Pi'     => 'Π',
  'Rho'    => 'Ρ',
  'Sigma'  => 'Σ',
  'Tau'    => 'Τ',
  'Upsilon'=> 'Υ',
  'Phi'    => 'Φ',
  'Chi'    => 'Χ',
  'Psi'    => 'Ψ',
  'Omega'  => 'Ω',
  'alpha'  => 'α',
  'beta'   => 'β',
  'gamma'  => 'γ',
  'delta'  => 'δ',
  'epsilon'=> 'ε',
  'zeta'   => 'ζ',
  'eta'    => 'η',
  'theta'  => 'θ',
  'iota'   => 'ι',
  'kappa'  => 'κ',
  'lambda' => 'λ',
  'mu'     => 'μ',
  'nu'     => 'ν',
  'xi'     => 'ξ',
  'omicron'=> 'ο',
  'pi'     => 'π',
  'rho'    => 'ρ',
  'sigma'  => 'σ',
  'tau'    => 'τ',
  'upsilon'=> 'υ',
  'phi'    => 'φ',
  'chi'    => 'χ',
  'psi'    => 'ψ',
  'omega'  => 'ω',
  'thetasym'=>'ϑ',
  'upsih'  => 'ϒ',
  'piv'    => 'ϖ',
  'ensp'   => "\x{2003}",	# normal wide space
  'emsp'   => "\x{2004}",	# wide space
  'thinsp' => "\x{2009}",	# very thin space
  'zwnj'   => "\x{200c}",	# zero-width-non-joiner
  'zwj'    => "\x{200d}",	# zero-width-joiner
  'lrm'    => "\x{200e}",	# left-to-right
  'rlm'    => "\x{200f}",	# right-to-left
  'ndash'  => '–',
  'mdash'  => '—',
  'lsquo'  => '‘',
  'rsquo'  => '’',
  'sbquo'  => '‚',
  'ldquo'  => '“',
  'rdquo'  => '”',
  'bdquo'  => '„',
  'dagger' => '†',
  'Dagger' => '‡',
  'bull'   => '•',
  'hellip' => '…',
  'permil' => '‰',
  'prime'  => '′',
  'Prime'  => '′',
  'lsaquo' => '‹',
  'rsaquo' => '›',
  'oline'  => '‾',
  'frasl'  => '⁄',
  'euro'   => '€',
  'image'  => 'ℑ',
  'weierp' => '℘',
  'real'   => 'ℜ',
  'trade'  => '™',
  'alefsym'=> 'ℵ',
  'larr'   => '←',
  'uarr'   => '↑',
  'rarr'   => '→',
  'darr'   => '↓',
  'harr'   => '↔',
  'crarr'  => '↵',
  'lArr'   => '⇐',
  'uArr'   => '⇑',
  'rArr'   => '⇒',
  'dArr'   => '⇓',
  'hArr'   => '⇔',
  'forall' => '∀',
  'part'   => '∂',
  'exist'  => '∃',
  'empty'  => '∅',
  'nabla'  => '∇',
  'isin'   => '∈',
  'notin'  => '∉',
  'ni'     => '∋',
  'prod'   => '∏',
  'sum'    => '∑',
  'minus'  => '−',
  'lowast' => '∗',
  'radic'  => '√',
  'prop'   => '∝',
  'infin'  => '∞',
  'ang'    => '∠',
  'and'    => '∧',
  'or'     => '∨',
  'cap'    => '∩',
  'cup'    => '∪',
  'int'    => '∫',
  'there4' => '∴',
  'sim'    => '∼',
  'cong'   => '≅',
  'asymp'  => '≃',
  'ne'     => '≠',
  'eq'     => '=',
  'le'     => '≤',
  'ge'     => '≥',
  'sub'    => '⊂',
  'sup'    => '⊃',
  'nsub'   => '⊄',
  'nsup'   => '⊅',
  'sube'   => '⊆',
  'supe'   => '⊇',
  'oplus'  => '⊕',
  'otimes' => '⊗',
  'perp'   => '⊥',
  'sdot'   => '⋅',
  'lceil'  => '⌈',
  'rceil'  => '⌉',
  'lfloor' => '⌊',
  'rfloor' => '⌋',
  'lang'   => '〈',
  'rang'   => '〉',
  'roz'    => '◊',
  'spades' => '♠',
  'clubs'  => '♣',
  'diamonds'=>'♦',
  'hearts' => '♥',
  );

sub _unquote_attribute
  {
  my ($self,$name,$val) = @_;

  my $html_like = 0;
  if ($name eq 'label')
    {
    $html_like = 1 if $val =~ /^\s*<\s*</;
    # '< >' => ' ', ' < a > ' => ' a '
    if ($html_like == 0 && $val =~ /\s*<(.*)>\s*\z/)
      {
      $val = $1; $val = ' ' if $val eq '';
      }
    }
  
  my $v = $self->_unquote($val);

  # Now HTML labels always start with "<", while non-HTML labels
  # start with " <" or anything else.
  if ($html_like == 0)
    {
    $v = ' ' . $v if $v =~ /^</;
    }
  else
    {
    $v =~ s/^\s*//; $v =~ s/\s*\z//;
    }

  $v;
  }

sub _unquote
  {
  my ($self, $name) = @_;

  $name = '' unless defined $name;

  # string concat
  # "foo" + " bar" => "foo bar"
  $name =~ s/^
    "((?:\\"|[^"])*)"			# "foo"
    \s*\+\s*"((?:\\"|[^"])*)"		# followed by ' + "bar"'
    /"$1$2"/x
  while $name =~ /^
    "(?:\\"|[^"])*"			# "foo"
    \s*\+\s*"(?:\\"|[^"])*"		# followed by ' + "bar"'
    /x;

  # map "&!;" to "!"
  $name =~ s/&(.);/$1/g;

  # map "&amp;" to "&"
  $name =~ s/&([^;]+);/$entities{$1} || '';/eg;

  # "foo bar" => foo bar
  $name =~ s/^"\s*//; 		# remove left-over quotes
  $name =~ s/\s*"\z//; 

  # unquote special chars
  $name =~ s/\\([\[\(\{\}\]\)#"])/$1/g;

  $name;
  }

sub _clean_line
  { 
  # do some cleanups on a line before handling it
  my ($self,$line) = @_;

  chomp($line);

  # collapse white space at start
  $line =~ s/^\s+//;
  # line ending in '\' means a continuation
  $line =~ s/\\\z//;

  $line;
  }

sub _line_insert
  {
  # "a1 -> a2\na3 -> a4" => "a1 -> a2 a3 -> a4"
  ' ';
  }

#############################################################################

sub _match_boolean
  {
  # not used yet, match a boolean value
  qr/(true|false|\d+)/;
  }

sub _match_comment
  {
  # match the start of a comment

  # // comment
  qr#(:[^\\]|)//#;
  }

sub _match_multi_line_comment
  {
  # match a multi line comment

  # /* * comment * */
  qr#(?:\s*/\*.*?\*/\s*)+#;
  }

sub _match_optional_multi_line_comment
  {
  # match a multi line comment

  # "/* * comment * */" or /* a */ /* b */ or ""
  qr#(?:(?:\s*/\*.*?\*/\s*)*|\s+)#;
  }

sub _match_name
  {
  # Return a regexp that matches an ID in the DOT language.
  # See http://www.graphviz.org/doc/info/lang.html for reference.

  # "node", "graph", "edge", "digraph", "subgraph" and "strict" are reserved:
  qr/\s*
    (
	# double quoted string
      "(?:\\"|[^"])*"			# "foo"
      (?:\s*\+\s*"(?:\\"|[^"])*")*	# followed by 0 or more ' + "bar"'
    |
	# number
     -?					# optional minus sign
	(?:				# non-capture group
	\.[0-9]+				# .00019
	|				 # or
	[0-9]+(?:\.[0-9]*)?			# 123 or 123.1
	)
    |
	# plain node name (a-z0-9_+)
     (?!(?i:node|edge|digraph|subgraph|graph|strict)\s)[\w]+
    )/xi;
  }

sub _match_node
  {
  # Return a regexp that matches something like '"bonn"' or 'bonn' or 'bonn:f1'
  my $self = shift;

  my $qr_n = $self->_match_name();

  # Examples: "bonn", "Bonn":f1, "Bonn":"f1", "Bonn":"port":"w", Bonn:port:w
  qr/
	$qr_n				# node name (see _match_name)
	(?:
	  :$qr_n
	  (?: :(n|ne|e|se|s|sw|w|nw) )?	# :port:compass_direction
	  |
	  :(n|ne|e|se|s|sw|w|nw)	# :compass_direction
	  )?				# optional
    /x;
  }

sub _match_group_start
  {
  # match a subgraph at the beginning (f.i. "graph { ")
  my $self = shift;
  my $qr_n = $self->_match_name();

  qr/^\s*(?:strict\s+)?(?:(?i)digraph|subgraph|graph)\s+$qr_n\s*\{/i;
  }

sub _match_pseudo_group_start_at_beginning
  {
  # match an anonymous group start at the beginning (aka " { ")
  qr/^\s*\{/;
  }

sub _match_pseudo_group_start
  {
  # match an anonymous group start (aka " { ")
  qr/\s*\{/;
  }

sub _match_group_end
  {
  # return a regexp that matches something like " }" or "} ;".
  qr/^\s*\}\s*;?\s*/;
  }

sub _match_edge
  {
  # Matches an edge
  qr/\s*(->|--)/;
  }

sub _match_html_regexps
  {
  # Return hash with regexps matching different parts of an HTML label.
  my $qr = 
  {
    # BORDER="2"
    attribute 	=> qr/\s*([A-Za-z]+)\s*=\s*"((?:\\"|[^"])*)"/,
    # BORDER="2" COLSPAN="2"
    attributes 	=> qr/(?:\s+(?:[A-Za-z]+)\s*=\s*"(?:\\"|[^"])*")*/,
    text	=> qr/.*?/,
    tr		=> qr/\s*<TR>/i,
    tr_end	=> qr/\s*<\/TR>/i,
    td		=> qr/\s*<TD[^>]*>/i,
    td_tag	=> qr/\s*<TD\s*/i,
    td_end	=> qr/\s*<\/TD>/i,
    table	=> qr/\s*<TABLE[^>]*>/i,
    table_tag	=> qr/\s*<TABLE\s*/i,
    table_end	=> qr/\s*<\/TABLE>/i,
  };
  $qr->{row} = qr/$qr->{tr}(?:$qr->{td}$qr->{text}$qr->{td_end})*$qr->{tr_end}/;

  $qr;
  }

sub _match_html
  {
  # build a giant regular expression that matches an HTML label

#    label=<
#    <TABLE BORDER="2" CELLBORDER="1" CELLSPACING="0" BGCOLOR="#ffffff">
#      <TR><TD PORT="portname" COLSPAN="3" BGCOLOR="#aabbcc" ALIGN="CENTER">port</TD></TR>
#      <TR><TD PORT="port2" COLSPAN="2" ALIGN="LEFT">port2</TD><TD PORT="port3" ALIGN="LEFT">port3</TD></TR>
#    </TABLE>>

  my $qr = _match_html_regexps();

  # < <TABLE> .. </TABLE> >
  qr/<$qr->{table}(?:$qr->{row})*$qr->{table_end}\s*>/;
  }
  
sub _match_single_attribute
  {
  my $qr_html = _match_html();

  qr/\s*(\w+)\s*=\s*		# the attribute name (label=")
    (
      "(?:\\"|[^"])*"			# "foo"
      (?:\s*\+\s*"(?:\\"|[^"])*")*	# followed by 0 or more ' + "bar"'
    |
      $qr_html				# or < <TABLE>..<\/TABLE> >
    |
      <[^>]*>				# or something like < a >
    |
      [^<][^,\]\}\n\s;]*		# or simple 'fooobar'
    )
    [,\]\n\}\s;]?\s*/x;		# possible ",", "\n" etc.
  }

sub _match_special_attribute
  {
  # match boolean attributes, these can appear without a value
  qr/\s*(
  center|
  compound|
  concentrate|
  constraint|
  decorate|
  diredgeconstraints|
  fixedsize|
  headclip|
  labelfloat|
  landscape|
  mosek|
  nojustify|
  normalize|
  overlap|
  pack|
  pin|
  regular|
  remincross|
  root|
  splines|
  tailclip|
  truecolor
  )[,;\s]?\s*/x;
  }

sub _match_attributes
  {
  # return a regexp that matches something like " [ color=red; ]" and returns
  # the inner text without the []

  my $qr_att = _match_single_attribute();
  my $qr_satt = _match_special_attribute();
  my $qr_cmt = _match_multi_line_comment();
 
  qr/\s*\[\s*((?:$qr_att|$qr_satt|$qr_cmt)*)\s*\];?/;
  }

sub _match_graph_attribute
  {
  # return a regexp that matches something like " color=red; " for attributes
  # that apply to a graph/subgraph
  qr/^\s*(\w+\s*=\s*("[^"]+"|[^;\n\s]+))([;\n\s]\s*|\z)/;
  }

sub _match_optional_attributes
  {
  # return a regexp that matches something like " [ color=red; ]" and returns
  # the inner text with the []

  my $qr_att = _match_single_attribute();
  my $qr_satt = _match_special_attribute();
  my $qr_cmt = _match_multi_line_comment();
 
  qr/\s*(\[\s*((?:$qr_att|$qr_satt|$qr_cmt)*)\s*\])?;?/;
  }

sub _clean_attributes
  {
  my ($self,$text) = @_;

  $text =~ s/^\s*\[\s*//;		# remove left-over "[" and spaces
  $text =~ s/\s*;?\s*\]\s*\z//;		# remove left-over "]" and spaces

  $text;
  }

#############################################################################

sub _new_scope
  {
  # create a new scope, with attributes from current scope
  my ($self, $is_group) = @_;

  my $scope = {};

  if (@{$self->{scope_stack}} > 0)
    {
    my $old_scope = $self->{scope_stack}->[-1];

    # make a copy of the old scope's attributes
    for my $t (keys %$old_scope)
      {
      next if $t =~ /^_/;
      my $s = $old_scope->{$t};
      $scope->{$t} = {} unless ref $scope->{$t}; my $sc = $scope->{$t};
      for my $k (keys %$s)
        {
	# skip things like "_is_group"
        $sc->{$k} = $s->{$k} unless $k =~ /^_/;
        }
      }
    }
  $scope->{_is_group} = 1 if defined $is_group;

  push @{$self->{scope_stack}}, $scope;
  $scope;
  }

sub _add_group_match
  {
  # register handlers for group start/end
  my $self = shift;

  my $qr_pseudo_group_start = $self->_match_pseudo_group_start_at_beginning();
  my $qr_group_start = $self->_match_group_start();
  my $qr_group_end   = $self->_match_group_end();
  my $qr_edge  = $self->_match_edge();
  my $qr_ocmt  = $self->_match_optional_multi_line_comment();

  # "subgraph G {"
  $self->_register_handler( $qr_group_start,
    sub
      {
      my $self = shift;
      my $graph = $self->{_graph};
      my $gn = $self->_unquote($1);
      print STDERR "# Parser: found subcluster '$gn'\n" if $self->{debug};
      push @{$self->{group_stack}}, $self->_new_group($gn);
      $self->_new_scope( 1 );
      1;
      } );
  
  # "{ "
  $self->_register_handler( $qr_pseudo_group_start,
    sub
      {
      my $self = shift;
      print STDERR "# Parser: Creating new scope\n" if $self->{debug};
      $self->_new_scope();
      # forget the left side
      $self->{left_edge} = undef;
      $self->{left_stack} = [ ];
      1;
      } );

  # "} -> " group/cluster/scope end with an edge
  $self->_register_handler( qr/$qr_group_end$qr_ocmt$qr_edge/,
    sub
      {
      my $self = shift;

      my $scope = pop @{$self->{scope_stack}};
      return $self->parse_error(0) if !defined $scope;

      if ($scope->{_is_group} && @{$self->{group_stack}})
        {
        print STDERR "# Parser: end subcluster '$self->{group_stack}->[-1]->{name}'\n" if $self->{debug};
        pop @{$self->{group_stack}};
        }
      else { print STDERR "# Parser: end scope\n" if $self->{debug}; }

      1;
      }, 
    sub
      {
      my ($self, $line) = @_;
      $line =~ qr/$qr_group_end$qr_edge/;
      $1 . ' ';
      } );

  # "}" group/cluster/scope end
  $self->_register_handler( $qr_group_end,
    sub
      {
      my $self = shift;
 
      my $scope = pop @{$self->{scope_stack}};
      return $self->parse_error(0) if !defined $scope;

      if ($scope->{_is_group} && @{$self->{group_stack}})
        {
        print STDERR "# Parser: end subcluster '$self->{group_stack}->[-1]->{name}'\n" if $self->{debug};
        pop @{$self->{group_stack}};
        }
      # always reset the stack
      $self->{stack} = [ ];
      1;
      } );
  }

sub _edge_style
  {
  # To convert "--" or "->" we simple do nothing, since the edge style in
  # Graphviz can only be set via the attribute "style"
  my ($self, $ed) = @_;

  'solid';
  }

sub _new_nodes
  {
  my ($self, $name, $group_stack, $att, $port, $stack) = @_;

  $port = '' unless defined $port;
  my @rc = ();
  # "name1" => "name1"
  if ($port ne '')
    {
    # create a special node
    $name =~ s/^"//; $name =~ s/"\z//;
    $port =~ s/^"//; $port =~ s/"\z//;
    # XXX TODO: find unique name?
    @rc = $self->_new_node ($self->{_graph}, "$name:$port", $group_stack, $att, $stack);
    my $node = $rc[0];
    $node->{_graphviz_portlet} = $port;
    $node->{_graphviz_basename} = $name;
    }
  else
    {
    @rc = $self->_new_node ($self->{_graph}, $name, $group_stack, $att, $stack);
    }
  @rc;
  }

sub _build_match_stack
  {
  my $self = shift;

  my $qr_node  = $self->_match_node();
  my $qr_name  = $self->_match_name();
  my $qr_cmt   = $self->_match_multi_line_comment();
  my $qr_ocmt  = $self->_match_optional_multi_line_comment();
  my $qr_attr  = $self->_match_attributes();
  my $qr_gatr  = $self->_match_graph_attribute();
  my $qr_oatr  = $self->_match_optional_attributes();
  my $qr_edge  = $self->_match_edge();
  my $qr_pgr = $self->_match_pseudo_group_start();

  # remove multi line comments /* comment */
  $self->_register_handler( qr/^$qr_cmt/, undef );
  
  # remove single line comment // comment
  $self->_register_handler( qr/^\s*\/\/.*/, undef );
  
  # simple remove the graph start, but remember that we did this
  $self->_register_handler( qr/^\s*((?i)strict)?$qr_ocmt((?i)digraph|graph)$qr_ocmt$qr_node$qr_ocmt\{/, 
    sub 
      {
      my $self = shift;
      return $self->parse_error(6) if @{$self->{scope_stack}} > 0; 
      $self->{_graphviz_graph_name} = $3; 
      $self->_new_scope(1);
      $self->{_graph}->set_attribute('type','undirected') if lc($2) eq 'graph';
      1;
      } );

  # simple remove the graph start, but remember that we did this
  $self->_register_handler( qr/^\s*(strict)?$qr_ocmt(di)?graph$qr_ocmt\{/i, 
    sub 
      {
      my $self = shift;
      return $self->parse_error(6) if @{$self->{scope_stack}} > 0; 
      $self->{_graphviz_graph_name} = 'unnamed'; 
      $self->_new_scope(1);
      $self->{_graph}->set_attribute('type','undirected') if lc($2) ne 'di';
      1;
      } );

  # end-of-statement
  $self->_register_handler( qr/^\s*;/, undef );

  # cluster/subgraph "subgraph G { .. }"
  # scope (dummy group): "{ .. }" 
  # scope/group/subgraph end: "}"
  $self->_add_group_match();

  # node [ color="red" ] etc.
  # The "(?i)" makes the keywords match case-insensitive. 
  $self->_register_handler( qr/^\s*((?i)node|graph|edge)$qr_ocmt$qr_attr/,
    sub
      {
      my $self = shift;
      my $type = lc($1 || '');
      my $att = $self->_parse_attributes($2 || '', $type, NO_MULTIPLES );
      return undef unless defined $att;		# error in attributes?

      if ($type ne 'graph')
	{
	# apply the attributes to the current scope
	my $scope = $self->{scope_stack}->[-1];
        $scope->{$type} = {} unless ref $scope->{$type};
	my $s = $scope->{$type};
	for my $k (keys %$att)
	  {
          $s->{$k} = $att->{$k}; 
	  }
	}
      else
	{
	my $graph = $self->{_graph};
	$graph->set_attributes ($type, $att);
	}

      # forget stacks
      $self->{stack} = [];
      $self->{left_edge} = undef;
      $self->{left_stack} = [];
      1;
      } );

  # color=red; (for graphs or subgraphs)
  $self->_register_attribute_handler($qr_gatr, 'parent');
  # [ color=red; ] (for nodes/edges)
  $self->_register_attribute_handler($qr_attr);

  # node chain continued like "-> { ... "
  $self->_register_handler( qr/^$qr_edge$qr_ocmt$qr_pgr/,
    sub
      {
      my $self = shift;

      return if @{$self->{stack}} == 0;	# only match this if stack non-empty

      my $graph = $self->{_graph};
      my $eg = $1;					# entire edge ("->" etc)

      my $edge_un = 0; $edge_un = 1 if $eg eq '--';	# undirected edge?

      # need to defer edge attribute parsing until the edge exists
      # if inside a scope, set the scope attributes, too:
      my $scope = $self->{scope_stack}->[-1] || {};
      my $edge_atr = $scope->{edge} || {};

      # create a new scope
      $self->_new_scope();

      # remember the left side
      $self->{left_edge} = [ 'solid', '', $edge_atr, 0, $edge_un ];
      $self->{left_stack} = $self->{stack};

      # forget stack and remember the right side instead
      $self->{stack} = [];

      1;
      } );

  # "Berlin"
  $self->_register_handler( qr/^$qr_node/,
    sub
      {
      my $self = shift;
      my $graph = $self->{_graph};

      # only match this inside a "{ }" (normal, non-group) scope
      return if exists $self->{scope_stack}->[-1]->{_is_group};

      my $n1 = $1;
      my $port = $2;
      push @{$self->{stack}},
        $self->_new_nodes ($n1, $self->{group_stack}, {}, $port, $self->{stack}); 

      if (defined $self->{left_edge})
        {
        my $e = $self->{use_class}->{edge};
        my ($style, $edge_label, $edge_atr, $edge_bd, $edge_un) = @{$self->{left_edge}};

        foreach my $node (@{$self->{left_stack}})
          {
          my $edge = $e->new( { style => $style, name => $edge_label } );

	  # if inside a scope, set the scope attributes, too:
	  my $scope = $self->{scope_stack}->[-1];
          $edge->set_attributes($scope->{edge}) if $scope;

	  # override with the local attributes 
	  # 'string' => [ 'string' ]
	  # [ { hash }, 'string' ] => [ { hash }, 'string' ]
	  my $e = $edge_atr; $e = [ $edge_atr ] unless ref($e) eq 'ARRAY';

	  for my $a (@$e)
	    {
	    if (ref $a)
	    {
	    $edge->set_attributes($a);
	    }
	  else
	    {
	    # deferred parsing with the object as param:
	    my $out = $self->_parse_attributes($a, $edge, NO_MULTIPLES);
            return undef unless defined $out;		# error in attributes?
	    $edge->set_attributes($out);
	    }
	  }

          # "<--->": bidirectional
          $edge->bidirectional(1) if $edge_bd;
          $edge->undirected(1) if $edge_un;
          $graph->add_edge ( $node, $self->{stack}->[-1], $edge );
          }
        }
      1;
      } );

  # "Berlin" [ color=red ] or "Bonn":"a" [ color=red ]
  $self->_register_handler( qr/^$qr_node$qr_oatr/,
    sub
      {
      my $self = shift;
      my $name = $1;
      my $port = $2;
      my $compass = $4 || ''; $port .= ":$compass" if $compass;

      $self->{stack} = [ $self->_new_nodes ($name, $self->{group_stack}, {}, $port ) ];

      # defer attribute parsing until object exists
      my $node = $self->{stack}->[0];
      my $a1 = $self->_parse_attributes($5||'', $node);
      return undef if $self->{error};
      $node->set_attributes($a1);

      # forget left stack
      $self->{left_edge} = undef;
      $self->{left_stack} = [];
      1;
      } );

  # Things like ' "Node" ' will be consumed before, so we do not need a case
  # for '"Bonn" -> "Berlin"'

  # node chain continued like "-> "Kassel" [ ... ]"
  $self->_register_handler( qr/^$qr_edge$qr_ocmt$qr_node$qr_ocmt$qr_oatr/,
    sub
      {
      my $self = shift;

      return if @{$self->{stack}} == 0;	# only match this if stack non-empty

      my $graph = $self->{_graph};
      my $eg = $1;					# entire edge ("->" etc)
      my $n = $2;					# node name
      my $port = $3;
      my $compass = $4 || $5 || ''; $port .= ":$compass" if $compass;

      my $edge_un = 0; $edge_un = 1 if $eg eq '--';	# undirected edge?

      my $scope = $self->{scope_stack}->[-1] || {};

      # need to defer edge attribute parsing until the edge exists
      my $edge_atr = [ $6||'', $scope->{edge} || {} ];

      # the right side nodes:
      my $nodes_b = [ $self->_new_nodes ($n, $self->{group_stack}, {}, $port) ];

      my $style = $self->_link_lists( $self->{stack}, $nodes_b,
	'--', '', $edge_atr, 0, $edge_un);

      # remember the left side
      $self->{left_edge} = [ $style, '', $edge_atr, 0, $edge_un ];
      $self->{left_stack} = $self->{stack};

      # forget stack and remember the right side instead
      $self->{stack} = $nodes_b;
      1;
      } );

  $self;
  }

sub _add_node
  {
  # add a node to the graph, overridable by subclasses
  my ($self, $graph, $name) = @_;

  # "a -- clusterB" should not create a spurious node named "clusterB"
  my @groups = $graph->groups();
  for my $g (@groups)
    {
    return $g if $g->{name} eq $name;
    }

  my $node = $graph->node($name);
 
  if (!defined $node)
    {
    $node = $graph->add_node($name);		# add

    # apply attributes from the current scope (only for new nodes)
    my $scope = $self->{scope_stack}->[-1];
    return $self->error("Scope stack is empty!") unless defined $scope;
  
    my $is_group = $scope->{_is_group};
    delete $scope->{_is_group};
    $node->set_attributes($scope->{node});
    $scope->{_is_group} = $is_group if $is_group;
    }

  $node;
  }

#############################################################################
# attribute remapping

# undef => drop that attribute
# not listed attributes will result in "x-dot-$attribute" and a warning

my $remap = {
  'node' => {
    'distortion' => 'x-dot-distortion',

    'fixedsize' => undef,
    'group' => 'x-dot-group',
    'height' => 'x-dot-height',

    # XXX TODO: ignore non-node attributes set in a scope
    'dir' => undef,

    'layer' => 'x-dot-layer',
    'margin' => 'x-dot-margin',
    'orientation' => \&_from_graphviz_node_orientation,
    'peripheries' => \&_from_graphviz_node_peripheries,
    'pin' => 'x-dot-pin',
    'pos' => 'x-dot-pos',
    # XXX TODO: rank=0 should make that node the root node
#   'rank' => undef,
    'rects' => 'x-dot-rects',
    'regular' => 'x-dot-regular',
#    'root' => undef,
    'sides' => 'x-dot-sides',
    'shapefile' => 'x-dot-shapefile',
    'shape' => \&_from_graphviz_node_shape,
    'skew' => 'x-dot-skew',
    'style' => \&_from_graphviz_style,
    'width' => 'x-dot-width',
    'z' => 'x-dot-z',
    },

  'edge' => {
    'arrowsize' => 'x-dot-arrowsize',
    'arrowhead' => \&_from_graphviz_arrow_style,
    'arrowtail' => 'x-dot-arrowtail',
     # important for color lists like "red:red" => double edge
    'color' => \&_from_graphviz_edge_color,
    'constraint' => 'x-dot-constraint',
    'dir' => \&_from_graphviz_edge_dir,
    'decorate' => 'x-dot-decorate',
    'f' => 'x-dot-f',
    'headclip' => 'x-dot-headclip',
    'headhref' => 'headlink',
    'headurl' => 'headlink',
    'headport' => \&_from_graphviz_headport,
    'headlabel' => 'headlabel',
    'headtarget' => 'x-dot-headtarget',
    'headtooltip' => 'headtitle',
    'labelangle' => 'x-dot-labelangle',
    'labeldistance' => 'x-dot-labeldistance',
    'labelfloat' => 'x-dot-labelfloat',
    'labelfontcolor' => \&_from_graphviz_color,
    'labelfontname' => 'font',
    'labelfontsize' => 'font-size',
    'layer' => 'x-dot-layer',
    'len' => 'x-dot-len',
    'lhead' => 'x-dot-lhead',
    'ltail' => 'x-dot-tail',
    'minlen' => \&_from_graphviz_edge_minlen,
    'pos' => 'x-dot-pos',
    'samehead' => 'x-dot-samehead',
    'samearrowhead' => 'x-dot-samearrowhead',
    'sametail' => 'x-dot-sametail',
    'style' => \&_from_graphviz_edge_style,
    'tailclip' => 'x-dot-tailclip',
    'tailhref' => 'taillink',
    'tailurl' => 'taillink',
    'tailport' => \&_from_graphviz_tailport,
    'taillabel' => 'taillabel',
    'tailtarget' => 'x-dot-tailtarget',
    'tailtooltip' => 'tailtitle',
    'weight' => 'x-dot-weight',
    },

  'graph' => {
    'damping' => 'x-dot-damping',
    'K' => 'x-dot-k',
    'bb' => 'x-dot-bb',
    'center' => 'x-dot-center',
    # will be handled automatically:
    'charset' => undef,
    'clusterrank' => 'x-dot-clusterrank',
    'compound' => 'x-dot-compound',
    'concentrate' => 'x-dot-concentrate',
    'defaultdist' => 'x-dot-defaultdist',
    'dim' => 'x-dot-dim',
    'dpi' => 'x-dot-dpi',
    'epsilon' => 'x-dot-epsilon',
    'esep' => 'x-dot-esep',
    'fontpath' => 'x-dot-fontpath',
    'labeljust' => \&_from_graphviz_graph_labeljust,
    'labelloc' => \&_from_graphviz_labelloc,
    'landscape' => 'x-dot-landscape',
    'layers' => 'x-dot-layers',
    'layersep' => 'x-dot-layersep',
    'levelsgap' => 'x-dot-levelsgap',
    'margin' => 'x-dot-margin',
    'maxiter' => 'x-dot-maxiter',
    'mclimit' => 'x-dot-mclimit',
    'mindist' => 'x-dot-mindist',
    'minquit' => 'x-dot-minquit',
    'mode' => 'x-dot-mode',
    'model' => 'x-dot-model',
    'nodesep' => 'x-dot-nodesep',
    'normalize' => 'x-dot-normalize',
    'nslimit' => 'x-dot-nslimit',
    'nslimit1' => 'x-dot-nslimit1',
    'ordering' => 'x-dot-ordering',
    'orientation' => 'x-dot-orientation',
    'output' => 'output',
    'outputorder' => 'x-dot-outputorder',
    'overlap' => 'x-dot-overlap',
    'pack' => 'x-dot-pack',
    'packmode' => 'x-dot-packmode',
    'page' => 'x-dot-page',
    'pagedir' => 'x-dot-pagedir',
    'pencolor' => \&_from_graphviz_color,
    'quantum' => 'x-dot-quantum',
    'rankdir' => \&_from_graphviz_graph_rankdir,
    'ranksep' => 'x-dot-ranksep',
    'ratio' => 'x-dot-ratio',
    'remincross' => 'x-dot-remincross',
    'resolution' => 'x-dot-resolution',
    'rotate' => 'x-dot-rotate',
    'samplepoints' => 'x-dot-samplepoints',
    'searchsize' => 'x-dot-searchsize',
    'sep' => 'x-dot-sep',
    'size' => 'x-dot-size',
    'splines' => 'x-dot-splines',
    'start' => 'x-dot-start',
    'style' => \&_from_graphviz_style,
    'stylesheet' => 'x-dot-stylesheet',
    'truecolor' => 'x-dot-truecolor',
    'viewport' => 'x-dot-viewport',
    'voro-margin' => 'x-dot-voro-margin',
    },

  'group' => {
    'labeljust' => \&_from_graphviz_graph_labeljust,
    'labelloc' => \&_from_graphviz_labelloc,
    'pencolor' => \&_from_graphviz_color,
    'style' => \&_from_graphviz_style,
    'K' => 'x-dot-k',
    },

  'all' => {
    'color' => \&_from_graphviz_color,
    'colorscheme' => 'x-colorscheme',
    'bgcolor' => \&_from_graphviz_color,
    'fillcolor' => \&_from_graphviz_color,
    'fontsize' => \&_from_graphviz_font_size,
    'fontcolor' => \&_from_graphviz_color,
    'fontname' => 'font',
    'lp' => 'x-dot-lp',
    'nojustify' => 'x-dot-nojustify',
    'rank' => 'x-dot-rank',
    'showboxes' => 'x-dot-showboxes',
    'target' => 'x-dot-target',
    'tooltip' => 'title',
    'URL' => 'link',
    'href' => 'link',
    },
  };

sub _remap { $remap; }

my $rankdir = {
  'LR' => 'east',
  'RL' => 'west',
  'TB' => 'south',
  'BT' => 'north',
  };

sub _from_graphviz_graph_rankdir
  {
  my ($self, $name, $dir, $object) = @_;

  my $d = $rankdir->{$dir} || 'east';

  ('flow', $d);
  }

my $shapes = {
  box => 'rect',
  polygon => 'rect',
  egg => 'rect',
  rectangle => 'rect',
  mdiamond => 'diamond',
  msquare => 'rect',
  plaintext => 'none',
  none => 'none',
  };

sub _from_graphviz_node_shape
  {
  my ($self, $name, $shape) = @_;

  my @rc;
  my $s = lc($shape);
  if ($s =~ /^(triple|double)/)
    {
    $s =~ s/^(triple|double)//;
    push @rc, ('border-style','double');
    }

  # map the name to what Graph::Easy expects (ellipse stays as ellipse f.i.)
  $s = $shapes->{$s} || $s;

  (@rc, $name, $s);
  }

sub _from_graphviz_style
  {
  my ($self, $name, $style, $class) = @_;

  my @styles = split /\s*,\s*/, $style;

  my $is_node = 0;
  $is_node = 1 if ref($class) && !$class->isa('Graph::Easy::Group');
  $is_node = 1 if !ref($class) && defined $class && $class eq 'node';

  my @rc;
  for my $s (@styles)
    {
    @rc = ('shape', 'rounded') if $s eq 'rounded';
    @rc = ('shape', 'invisible') if $s eq 'invis';
    @rc = ('border', 'black ' . $1) if $s =~ /^(bold|dotted|dashed)\z/;
    if ($is_node != 0)
      {	
      @rc = ('shape', 'rect') if $s eq 'filled';
      }
    # convert "setlinewidth(12)" => 
    if ($s =~ /setlinewidth\((\d+|\d*\.\d+)\)/)
      {
      my $width = abs($1 || 1);
      my $style = '';
      $style = 'wide';			# > 11
      $style = 'solid' if $width < 3;
      $style = 'bold' if $width >= 3 && $width < 5;
      $style = 'broad' if $width >= 5 && $width < 11;
      push @rc, ('borderstyle',$style);
      }
    }

  @rc;
  }

sub _from_graphviz_node_orientation
  {
  my ($self, $name, $o) = @_;

  my $r = int($o);
  
  return (undef,undef) if $r == 0;

  # 1.0 => 1
  ('rotate', $r);
  }

my $port_remap = {
  n => 'north',
  e => 'east',
  w => 'west',
  s => 'south',
  };

sub _from_graphviz_headport
  {
  my ($self, $name, $compass) = @_;

  # XXX TODO
  # handle "port:compass" too

  # one of "n","ne","e","se","s","sw","w","nw
  # "ne => n"
  my $c = $port_remap->{ substr(lc($compass),0,1) } || 'east';
 
  ('end', $c);
  }

sub _from_graphviz_tailport
  {
  my ($self, $name, $compass) = @_;

  # XXX TODO
  # handle "port:compass" too

  # one of "n","ne","e","se","s","sw","w","nw
  # "ne => n" => "north"
  my $c = $port_remap->{ substr(lc($compass),0,1) } || 'east';
  
  ('start', $c);
  }

sub _from_graphviz_node_peripheries
  {
  my ($self, $name, $cnt) = @_;

  return (undef,undef) if $cnt < 2;

  # peripheries = 2 => double border
  ('border-style', 'double');
  }

sub _from_graphviz_edge_minlen
  {
  my ($self, $name, $len) = @_;

  # 1 => 1, 2 => 3, 3 => 5 etc
  $len = $len * 2 - 1;
  ($name, $len);
  }

sub _from_graphviz_font_size
  {
  my ($self, $f, $size) = @_;

  # 20 => 20px
  $size = $size . 'px' if $size =~ /^\d+(\.\d+)?\z/;

  ('fontsize', $size);
  }

sub _from_graphviz_labelloc
  {
  my ($self, $name, $loc) = @_;

  my $l = 'top';
  $l = 'bottom' if $loc =~ /^b/;

  ('labelpos', $l);
  }

sub _from_graphviz_edge_dir
  {
  my ($self, $name, $dir, $edge) = @_;

  # Modify the edge, depending on dir
  if (ref($edge))
    {
    # "forward" is the default and ignored
    $edge->flip() if $dir eq 'back';
    $edge->bidirectional(1) if $dir eq 'both';
    $edge->undirected(1) if $dir eq 'none';
    }

  (undef, undef);
  }

sub _from_graphviz_edge_style
  {
  my ($self, $name, $style, $object) = @_;

  # input: solid dashed dotted bold invis
  $style = 'invisible' if $style eq 'invis';

  # although "normal" is not documented, it occurs in the wild
  $style = 'solid' if $style eq 'normal';

  # convert "setlinewidth(12)" => 
  if ($style =~ /setlinewidth\((\d+|\d*\.\d+)\)/)
    {
    my $width = abs($1 || 1);
    $style = 'wide';			# > 11
    $style = 'solid' if $width < 3;
    $style = 'bold' if $width >= 3 && $width < 5;
    $style = 'broad' if $width >= 5 && $width < 11;
    }

  ($name, $style);
  }

sub _from_graphviz_arrow_style
  {
  my ($self, $name, $shape, $object) = @_;

  my $style = 'open';

  $style = 'closed' if $shape =~ /^(empty|onormal)\z/;
  $style = 'filled' if $shape eq 'normal' || $shape eq 'normalnormal';
  $style = 'open' if $shape eq 'vee' || $shape eq 'veevee';
  $style = 'none' if $shape eq 'none' || $shape eq 'nonenone';

  ('arrow-style', $style);
  }

my $color_atr_map = {
  fontcolor => 'color',
  bgcolor => 'background',
  fillcolor => 'fill',
  pencolor => 'bordercolor',
  labelfontcolor => 'labelcolor',
  color => 'color',
  };

sub _from_graphviz_color
  {
  # Remap the color name and value
  my ($self, $name, $color) = @_;

  # "//red" => "red"
  $color =~ s/^\/\///;

  my $colorscheme = 'x11';
  if ($color =~ /^\//)
    {
    # "/set9/red" => "red"
    $color =~ s/^\/([^\/]+)\///;
    $colorscheme = $1;
    # map the color to the right color according to the colorscheme
    $color = Graph::Easy->color_value($color,$colorscheme) || 'black';
    }

  # "#AA BB CC => "#AABBCC"
  $color =~ s/\s+//g if $color =~ /^#/;

  # "0.1 0.4 0.5" => "hsv(0.1,0.4,0.5)"
  $color =~ s/\s+/,/g if $color =~ /\s/;
  $color = 'hsv(' . $color . ')' if $color =~ /,/;

  ($color_atr_map->{$name}, $color);
  }

sub _from_graphviz_edge_color
  {
  # remap the color name and value
  my ($self, $name, $color) = @_;

  my @colors = split /:/, $color;

  for my $c (@colors)
    {
    $c = Graph::Easy::Parser::Graphviz::_from_graphviz_color($self,$name,$c);
    }

  my @rc;
  if (@colors > 1)
    {
    # 'red:blue' => "style: double; color: red"
    push @rc, 'style', 'double';
    }

  (@rc, $color_atr_map->{$name}, $colors[0]);
  }

sub _from_graphviz_graph_labeljust
  {
  my ($self, $name, $l) = @_;

  # input: "l" "r" or "c", output "left", "right" or "center"
  my $a = 'center';
  $a = 'left' if $l eq 'l';
  $a = 'right' if $l eq 'r';

  ('align', $a);
  }

#############################################################################

sub _remap_attributes
  {
  my ($self, $att, $object, $r) = @_;

  if ($self->{debug})
    {
    my $o = ''; $o = " for $object" if $object;
    print STDERR "# remapping attributes '$att'$o\n";
    require Data::Dumper; print STDERR "#" , Data::Dumper::Dumper($att),"\n";
    }

  $r = $self->_remap() unless defined $r;

  $self->{_graph}->_remap_attributes($object, $att, $r, 'noquote', undef, undef);
  }

#############################################################################

my $html_remap = {
  'table' => {
    'align' => 'align',
    'balign' => undef,
    'bgcolor' => 'fill',
    'border' => 'border',
    # XXX TODO
    'cellborder' => 'border',
    'cellspacing' => undef,
    'cellpadding' => undef,
    'fixedsize' => undef,
    'height' => undef,
    'href' => 'link',
    'port' => undef,
    'target' => undef,
    'title' => 'title',
    'tooltip' => 'title',
    'valign' => undef,
    'width' => undef,
    },
  'td' => {
    'align' => 'align',
    'balign' => undef,
    'bgcolor' => 'fill',
    'border' => 'border',
    'cellspacing' => undef,
    'cellpadding' => undef,
    'colspan' => 'columns',
    'fixedsize' => undef,
    'height' => undef,
    'href' => 'link',
    'port' => undef,
    'rowspan' => 'rows',
    'target' => undef,
    'title' => 'title',
    'tooltip' => 'title',
    'valign' => undef,
    'width' => undef,
    },
  };

sub _parse_html_attributes
  {
  my ($self, $text, $qr, $tag) = @_;

  # "<TD ...>" => " ..."
  $text =~ s/^$qr->{td_tag}//;
  $text =~ s/\s*>\z//;

  my $attr = {};
  while ($text ne '')
    {

    return $self->error("HTML-like attribute '$text' doesn't look valid to me.")
      unless $text =~ s/^($qr->{attribute})//;

    my $name = lc($2); my $value = $3;

    $self->_unquote($value);
    $value = lc($value) if $name eq 'align';
    $self->error ("Unknown attribute '$name' in HTML-like label") unless exists $html_remap->{$tag}->{$name};
    # filter out attributes we do not yet support
    $attr->{$name} = $value if defined $html_remap->{$tag}->{$name};
    }

  $attr;
  }

sub _html_per_table
  {
  # take the HTML-like attributes found per TABLE and create a hash with them
  # so they can be applied as default to each node
  my ($self, $attributes) = @_;

  $self->_remap_attributes($attributes,'table',$html_remap);
  }

sub _html_per_node
  {
  # take the HTML-like attributes found per TD and apply them to the node
  my ($self, $attr, $node) = @_;

  my $c = $attr->{colspan} || 1;
  $node->set_attribute('columns',$c) if $c != 1;

  my $r = $attr->{rowspan} || 1;
  $node->set_attribute('rows',$r) if $r != 1;

  $node->{autosplit_portname} = $attr->{port} if exists $attr->{port};

  for my $k (qw/port colspan rowspan/)
    {
    delete $attr->{$k};
    }

  my $att = $self->_remap_attributes($attr,$node,$html_remap);
 
  $node->set_attributes($att);

  $self;
  }

sub _parse_html
  {
  # Given an HTML label, parses that into the individual parts. Returns a
  # list of nodes.
  my ($self, $n, $qr) = @_;

  my $graph = $self->{_graph};

  my $label = $n->label(1); $label = '' unless defined $label;
  my $org_label = $label;

#  print STDERR "# 1 HTML-like label is now: $label\n";

  # "unquote" the HTML-like label
  $label =~ s/^<\s*//;
  $label =~ s/\s*>\z//;

#  print STDERR "# 2 HTML-like label is now: $label\n";

  # remove the table end (at the end)
  $label =~ s/$qr->{table_end}\s*\z//;
#  print STDERR "# 2.a HTML-like label is now: $label\n";
  # remove the table start
  $label =~ s/($qr->{table})//;

#  print STDERR "# 3 HTML-like label is now: $label\n";

  my $table_tag = $1 || ''; 
  $table_tag =~ /$qr->{table_tag}(.*?)>/;
  my $table_attr = $self->_parse_html_attributes($1 || '', $qr, 'table');

#  use Data::Dumper;
#  print STDERR "# 3 HTML-like table-tag attributes are: ", Dumper($table_attr),"\n";

  # generate the base name from the actual graphviz node name to allow links to
  # it
  my $base_name = $n->{name};

  my $class = $self->{use_class}->{node};

  my $raw_attributes = $n->raw_attributes();
  delete $raw_attributes->{label};
  delete $raw_attributes->{shape};

  my @rc; my $first_in_row;
  my $x = 0; my $y = 0; my $idx = 0;
  while ($label ne '')
    {
    $label =~ s/^\s*($qr->{row})//;
  
    return $self->error ("Cannot parse HTML-like label: '$label'")
      unless defined $1;

    # we now got one row:
    my $row = $1;

#  print STDERR "# 3 HTML-like row is $row\n";

    # remove <TR>
    $row =~ s/^\s*$qr->{tr}\s*//; 
    # remove </TR>
    $row =~ s/\s*$qr->{tr_end}\s*\z//;

    my $first = 1;
    while ($row ne '')
      {
      # remove one TD from the current row text
      $row =~ s/^($qr->{td})($qr->{text})$qr->{td_end}//;
      return $self->error ("Cannot parse HTML-like row: '$row'")
        unless defined $1;

      my $node_label = $2;
      my $attr_txt = $1;

      # convert "<BR/>" etc. to line breaks
      # XXX TODO apply here the default of BALIGN
      $node_label =~ s/<BR\s*\/?>/\\n/gi;

      # if the font covers the entire node, set "font" attribute
      my $font_face = undef;
      if ($node_label =~ /^[ ]*<FONT FACE="([^"]+)">(.*)<\/FONT>[ ]*\z/i)
        {
        $node_label = $2; $font_face = $1;
        }
      # XXX TODO if not, allow inline font changes
      $node_label =~ s/<FONT[^>]+>(.*)<\/FONT>/$1/ig;

      my $node_name = $base_name . '.' . $idx;

      # if it doesn't exist, add it, otherwise retrieve node object to $node

      my $node = $graph->node($node_name);
      if (!defined $node)
	{
	# create node object from the correct class
	$node = $class->new($node_name);
        $graph->add_node($node);
	$node->set_attributes($raw_attributes);
        $node->{autosplit_portname} = $idx;		# some sensible default
	}

      # apply the default attributes from the table
      $node->set_attributes($table_attr);
      # if found a global font attribute, override the font attribute with it
      $node->set_attribute('font',$font_face) if defined $font_face;

      # parse the attributes and apply them to the node
      $self->_html_per_node( $self->_parse_html_attributes($attr_txt,$qr,'td'), $node );

#     print STDERR "# Created $node_name\n";
 
      $node->{autosplit_label} = $node_label;
      $node->{autosplit_basename} = $base_name;

      push @rc, $node;
      if (@rc == 1)
        {
        # for correct as_txt output
        $node->{autosplit} = $org_label;
        $node->{autosplit} =~ s/\s+\z//;	# strip trailing spaces
        $node->{autosplit} =~ s/^\s+//;		# strip leading spaces
        $first_in_row = $node;
        }
      else
        {
        # second, third etc. get previous as origin
        my ($sx,$sy) = (1,0);
        my $origin = $rc[-2];
	# the first node in one row is relative to the first node in the
	# prev row
	if ($first == 1)
          {
          ($sx,$sy) = (0,1); $origin = $first_in_row;
          $first_in_row = $node;
	  $first = 0;
          } 
        $node->relative_to($origin,$sx,$sy);
	# suppress as_txt output for other parts
	$node->{autosplit} = undef;
        }	
      # nec. for border-collapse
      $node->{autosplit_xy} = "$x,$y";

      $idx++;						# next node ID
      $x++;
      }

    # next row
    $y++;
    }

  # return created nodes
  @rc;
  }

#############################################################################

sub _parser_cleanup
  {
  # After initial parsing, do cleanup, e.g. autosplit nodes with shape record,
  # parse HTML-like labels, re-connect edges to the parts etc.
  my ($self) = @_;

  print STDERR "# Parser cleanup pass\n" if $self->{debug};

  my $g = $self->{_graph};
  my @nodes = $g->nodes();

  # For all nodes that have a shape of "record", break down their label into
  # parts and create these as autosplit nodes.
  # For all nodes that have a label starting with "<", parse it as HTML.

  # keep a record of all nodes to be deleted later:
  my $delete = {};

  my $html_regexps = $self->_match_html_regexps();
  my $graph_flow = $g->attribute('flow');
  for my $n (@nodes)
    {
    my $label = $n->label(1);
    # we can get away with a direct lookup, since DOT does not have classes
    my $shape = $n->{att}->{shape} || 'rect';

    if ($shape ne 'record' && $label =~ /^<\s*<.*>\z/)
      {
      print STDERR "# HTML-like label found: $label\n" if $self->{debug};
      my @nodes = $self->_parse_html($n, $html_regexps);
      # remove the temp. and spurious node
      $delete->{$n->{name}} = undef;
      my @edges = $n->edges();
      # reconnect the found edges to the new autosplit parts
      for my $e (@edges)
        {
        # XXX TODO: connect to better suited parts based on flow?
        $e->start_at($nodes[0]) if ($e->{from} == $n);
        $e->end_at($nodes[0]) if ($e->{to} == $n);
        }
      $g->del_node($n);
      next;
      }

    if ($shape eq 'record' && $label =~ /\|/)
      {
      my $att = {};
      # create basename only when node name differes from label
      $att->{basename} = $n->{name};
      if ($n->{name} ne $label)
	{
	$att->{basename} = $n->{name};
	}
      # XXX TODO: autosplit needs to handle nesting like "{}".

      # Replace "{ ... | ... |  ... }" with "...|| ... || ...." as a cheat
      # to fix some common cases
      if ($label =~ /^\s*\{[^\{\}]+\}\s*\z/)
	{
        $label =~ s/[\{\}]//g;	# {..|..} => ..|..
        # if flow up/down:    {A||B} => "[ A||  ||  B ]"
        $label =~ s/\|/\|\|  /g	# ..|.. => ..||  ..
	  if ($graph_flow =~ /^(east|west)/);
        # if flow left/right: {A||B} => "[ A|  |B ]"
        $label =~ s/\|\|/\|  \|/g	# ..|.. => ..|  |..
	  if ($graph_flow =~ /^(north|south)/);
	}
      my @rc = $self->_autosplit_node($g, $label, $att, 0 );
      my $group = $n->group();
      $n->del_attribute('label');

      my $qr_clean = $self->{_qr_part_clean};
      # clean the base name of ports:
      #  "<f1> test | <f2> test" => "test|test"
      $rc[0]->{autosplit} =~ s/(^|\|)$qr_clean/$1/g;
      $rc[0]->{att}->{basename} =~ s/(^|\|)$qr_clean/$1/g;
      $rc[0]->{autosplit} =~ s/^\s*//;
      $rc[0]->{att}->{basename} =~ s/^\s*//;
      # '| |' => '|  |' to avoid empty parts via as_txt() => as_ascii()
      $rc[0]->{autosplit} =~ s/\|\s\|/\|  \|/g;
      $rc[0]->{att}->{basename} =~ s/\|\s\|/\|  \|/g;
      $rc[0]->{autosplit} =~ s/\|\s\|/\|  \|/g;
      $rc[0]->{att}->{basename} =~ s/\|\s\|/\|  \|/g;
      delete $rc[0]->{att}->{basename} if $rc[0]->{att}->{basename} eq $rc[0]->{autosplit};

      for my $n1 (@rc)
	{
	$n1->add_to_group($group) if $group;
	$n1->set_attributes($n->{att});
	# remove the temp. "shape=record"
	$n1->del_attribute('shape');
	}

      # If the helper node has edges, reconnect them to the first
      # part of the autosplit node (dot seems to render them arbitrarily
      # on the autosplit node):

      for my $e (values %{$n->{edges}})
	{
        $e->start_at($rc[0]) if $e->{from} == $n;
        $e->end_at($rc[0]) if $e->{to} == $n;
	}
      # remove the temp. and spurious node
      $delete->{$n->{name}} = undef;
      $g->del_node($n);
      }
    }

  # During parsing, "bonn:f1" -> "berlin:f2" results in "bonn:f1" and
  # "berlin:f2" as nodes, plus an edge connecting them

  # We find all of these nodes, move the edges to the freshly created
  # autosplit parts above, then delete the superflous temporary nodes.

  # if we looked up "Bonn:f1", remember it here to save time:
  my $node_cache = {};

  my @edges = $g->edges();
  @nodes = $g->nodes();		# get a fresh list of nodes after split
  for my $e (@edges)
    {
    # do this for both the "from" and "to" side of the edge:
    for my $side ('from','to')
      {
      my $n = $e->{$side};
      next unless defined $n->{_graphviz_portlet};

      my $port = $n->{_graphviz_portlet};
      my $base = $n->{_graphviz_basename};

      my $compass = '';
      if ($port =~ s/:(n|ne|e|se|s|sw|w|nw)\z//)
	{
        $compass = $1;
	}
      # "Bonn:w" is port "w", and only "west" when that port doesnt exist	

      # look it up in the cache first
      my $node = $node_cache->{"$base:$port"};

      my $p = undef;
      if (!defined $node)
	{
	# go thru all nodes and for see if we find one with the right port name
	for my $na (@nodes)
	  {
	  next unless exists $na->{autosplit_portname} && exists $na->{autosplit_basename};
	  next unless $na->{autosplit_basename} eq $base;
	  next unless $na->{autosplit_portname} eq $port;
	  # cache result
          $node_cache->{"$base:$port"} = $na;
          $node = $na;
          $p = $port_remap->{substr($compass,0,1)} if $compass;		# ne => n => north
	  }
	}

      if (!defined $node)
	{
	# Still not defined?
        # port looks like a compass node?
	if ($port =~ /^(n|ne|e|se|s|sw|w|nw)\z/)
	  {
	  # get the first node matching the base
	  for my $na (@nodes)
	    {
	    #print STDERR "# evaluating $na ($na->{name} $na->{autosplit_basename}) ($base)\n";
	    next unless exists $na->{autosplit_basename};
	    next unless $na->{autosplit_basename} eq $base;
	    # cache result
	    $node_cache->{"$base:$port"} = $na;
	    $node = $na;
	    }
	  if (!defined $node)
	    {
	    return $self->error("Cannot find autosplit node for $base:$port on edge $e->{id}");
	    }
          $p = $port_remap->{substr($port,0,1)};		# ne => n => north
	  }
	else
	  {
	  # uhoh...
	  return $self->error("Cannot find autosplit node for $base:$port on edge $e->{id}");
	  }
 	}

      if ($side eq 'from')
	{
        $delete->{$e->{from}->{name}} = undef;
  	print STDERR "# Setting new edge start point to $node->{name}\n" if $self->{debug};
	$e->start_at($node);
  	print STDERR "# Setting new edge end point to start at $p\n" if $self->{debug} && $p;
	$e->set_attribute('start', $p) if $p;
	}
      else
	{
        $delete->{$e->{to}->{name}} = undef;
  	print STDERR "# Setting new edge end point to $node->{name}\n" if $self->{debug};
	$e->end_at($node);
  	print STDERR "# Setting new edge end point to end at $p\n" if $self->{debug} && $p;
	$e->set_attribute('end', $p) if $p;
	}

      } # end for side "from" and "to"
    # we have reconnected this edge
    }

  # after reconnecting all edges, we can delete temp. nodes: 
  for my $n (@nodes)
    {
    next unless exists $n->{_graphviz_portlet};
    # "c:w" => "c"
    my $name = $n->{name}; $name =~ s/:.*?\z//;
    # add "c" unless we should delete the base node (this deletes record
    # and autosplit nodes, but keeps loners like "c:w" around as "c":
    $g->add_node($name) unless exists $delete->{$name};
    # delete "c:w"
    $g->del_node($n); 
    }

  # if the graph doesn't have a title, set the graph name as title
  $g->set_attribute('title', $self->{_graphviz_graph_name})
    unless defined $g->raw_attribute('title');
  
  # cleanup if there are no groups
  if ($g->groups() == 0)
    {
    $g->del_attribute('group', 'align');
    $g->del_attribute('group', 'fill');
    }
  $g->{_warn_on_unknown_attributes} = 0;	# reset to die again

  $self;
  }

1;
__END__

=head1 NAME

Graph::Easy::Parser::Graphviz - Parse Graphviz text into Graph::Easy

=head1 SYNOPSIS

        # creating a graph from a textual description

        use Graph::Easy::Parser::Graphviz;
        my $parser = Graph::Easy::Parser::Graphviz->new();

        my $graph = $parser->from_text(
                "digraph MyGraph { \n" .
	 	"	Bonn -> \"Berlin\" \n }"
        );
        print $graph->as_ascii();

	print $parser->from_file('mygraph.dot')->as_ascii();

=head1 DESCRIPTION

C<Graph::Easy::Parser::Graphviz> parses the text format from the DOT language
use by Graphviz and constructs a C<Graph::Easy> object from it.

The resulting object can than be used to layout and output the graph
in various formats.

Please see the Graphviz manual for a full description of the syntax
rules of the DOT language.

=head2 Output

The output will be a L<Graph::Easy|Graph::Easy> object (unless overrriden
with C<use_class()>), see the documentation for Graph::Easy what you can do
with it.

=head2 Attributes

Attributes will be remapped to the proper Graph::Easy attribute names and
values, as much as possible.

Anything else will be converted to custom attributes starting with "x-dot-".
So "ranksep: 2" will become "x-dot-ranksep: 2".

=head1 METHODS

C<Graph::Easy::Parser::Graphviz> supports the same methods
as its parent class C<Graph::Easy::Parser>:

=head2 new()

	use Graph::Easy::Parser::Graphviz;
	my $parser = Graph::Easy::Parser::Graphviz->new();

Creates a new parser object. There are two valid parameters:

	debug
	fatal_errors

Both take either a false or a true value.

	my $parser = Graph::Easy::Parser::Graphviz->new( debug => 1 );
	$parser->from_text('digraph G { A -> B }');

=head2 reset()

	$parser->reset();

Reset the status of the parser, clear errors etc. Automatically called
when you call any of the C<from_XXX()> methods below.

=head2 use_class()

	$parser->use_class('node', 'Graph::Easy::MyNode');

Override the class to be used to constructs objects while parsing.

See L<Graph::Easy::Parser> for further information.

=head2 from_text()

	my $graph = $parser->from_text( $text );

Create a L<Graph::Easy|Graph::Easy> object from the textual description in C<$text>.

Returns undef for error, you can find out what the error was
with L<error()>.

This method will reset any previous error, and thus the C<$parser> object
can be re-used to parse different texts by just calling C<from_text()>
multiple times.

=head2 from_file()

	my $graph = $parser->from_file( $filename );
	my $graph = Graph::Easy::Parser->from_file( $filename );

Creates a L<Graph::Easy|Graph::Easy> object from the textual description in the file
C<$filename>.

The second calling style will create a temporary parser object,
parse the file and return the resulting C<Graph::Easy> object.

Returns undef for error, you can find out what the error was
with L<error()> when using the first calling style.

=head2 error()

	my $error = $parser->error();

Returns the last error, or the empty string if no error occured.

=head2 parse_error()

	$parser->parse_error( $msg_nr, @params);

Sets an error message from a message number and replaces embedded
templates like C<##param1##> with the passed parameters.

=head1 CAVEATS

The parser has problems with the following things:

=over 12

=item encoding and charset attribute

The parser assumes the input to be C<utf-8>. Input files in <code>Latin1</code>
are not parsed properly, even when they have the charset attribute set.

=item shape=record

Nodes with shape record are only parsed properly when the label does not
contain groups delimited by "{" and "}", so the following is parsed
wrongly:

	node1 [ shape=record, label="A|{B|C}" ]

=item default shape

The default shape for a node is 'rect', opposed to 'circle' as dot renders
nodes.

=item attributes

Some attributes are B<not> remapped properly to what Graph::Easy expects, thus
losing information, either because Graph::Easy doesn't support this feature
yet, or because the mapping is incomplete.

Some attributes meant only for nodes or edges etc. might be incorrectly applied
to other objects, resulting in unnec. warnings while parsing.

Attributes not valid in the original DOT language are silently ignored by dot,
but result in a warning when parsing under Graph::Easy. This helps catching all
these pesky misspellings, but it's not yet possible to disable these warnings.

=item comments

Comments written in the source code itself are discarded. If you want to have
comments on the graph, clusters, nodes or edges, use the attribute C<comment>.
These are correctly read in and stored, and then output into the different
formats, too.

=back

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>, L<Graph::Reader::Dot>.

=head1 AUTHOR

Copyright (C) 2005 - 2007 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut
#############################################################################
# Parse VCG text into a Graph::Easy object
#
#############################################################################

package Graph::Easy::Parser::VCG;

$VERSION = '0.06';
use Graph::Easy::Parser::Graphviz;
@ISA = qw/Graph::Easy::Parser::Graphviz/;

use strict;
use utf8;
use constant NO_MULTIPLES => 1;
use Encode qw/decode/;

sub _init
  {
  my $self = shift;

  $self->SUPER::_init(@_);
  $self->{attr_sep} = '=';

  $self;
  }

my $vcg_color_by_name = {};

my $vcg_colors = [
  white 	=> 'white',
  blue  	=> 'blue',	
  red 		=> 'red',
  green		=> 'green',
  yellow	=> 'yellow',
  magenta	=> 'magenta',
  cyan		=> 'cyan',
  darkgrey	=> 'rgb(85,85,85)',
  darkblue	=> 'rgb(0,0,128)',
  darkred	=> 'rgb(128,0,0)',
  darkgreen	=> 'rgb(0,128,0)',
  darkyellow	=> 'rgb(128,128,0)',
  darkmagenta	=> 'rgb(128,0,128)',
  darkcyan	=> 'rgb(0,128,128)',
  gold		=> 'rgb(255,215,0)',
  lightgrey	=> 'rgb(170,170,170)',
  lightblue	=> 'rgb(128,128,255)',
  lightred 	=> 'rgb(255,128,128)',
  lightgreen    => 'rgb(128,255,128)',
  lightyellow   => 'rgb(255,255,128)',
  lightmagenta  => 'rgb(255,128,255)',
  lightcyan 	=> 'rgb(128,255,255)',
  lilac 	=> 'rgb(238,130,238)',
  turquoise 	=> 'rgb(64,224,208)',
  aquamarine 	=> 'rgb(127,255,212)',
  khaki 	=> 'rgb(240,230,140)',
  purple 	=> 'rgb(160,32,240)',
  yellowgreen 	=> 'rgb(154,205,50)',
  pink		=> 'rgb(255,192,203)',
  orange 	=> 'rgb(255,165,0)',
  orchid	=> 'rgb(218,112,214)',
  black 	=> 'black',
  ];

  {
  for (my $i = 0; $i < @$vcg_colors; $i+=2)
    {
    $vcg_color_by_name->{$vcg_colors->[$i]} = $vcg_colors->[$i+1];
    }
  }

sub reset
  {
  my $self = shift;

  Graph::Easy::Parser::reset($self, @_);

  my $g = $self->{_graph};
  $self->{scope_stack} = [];

  $g->{_vcg_color_map} = [];
  for (my $i = 0; $i < @$vcg_colors; $i+=2)
    {
    # set the first 32 colors as the default
    push @{$g->{_vcg_color_map}}, $vcg_colors->[$i+1];
    }

  $g->{_vcg_class_names} = {};

  # allow some temp. values during parsing
  $g->_allow_special_attributes(
    {
    edge => {
      source => [ "", undef, '', '', undef, ],
      target => [ "", undef, '', '', undef, ],
    },
    } );

  $g->{_warn_on_unknown_attributes} = 1;

  # a hack to support multiline labels
  $self->{_in_vcg_multi_line_label} = 0;

  # set some default attributes on the graph object, because GDL has
  # some different defaults as Graph::Easy
  $g->set_attribute('flow', 'south');
  $g->set_attribute('edge', 'arrow-style', 'filled');
  $g->set_attribute('node', 'align', 'left');

  $self;
  }

sub _vcg_color_map_entry
  {
  my ($self, $index, $color) = @_;

  $color =~ /([0-9]+)\s+([0-9]+)\s+([0-9]+)/;
  $self->{_graph}->{_vcg_color_map}->[$index] = "rgb($1,$2,$3)";
  }

sub _unquote
  {
  my ($self, $name) = @_;

  $name = '' unless defined $name;

  # "foo bar" => foo bar
  # we need to use "[ ]" here, because "\s" also matches 0x0c, and
  # these color codes need to be kept intact:
  $name =~ s/^"[ ]*//; 		# remove left-over quotes
  $name =~ s/[ ]*"\z//; 

  # unquote special chars
  $name =~ s/\\([\[\(\{\}\]\)#"])/$1/g;

  $name;
  }

#############################################################################

sub _match_commented_line
  {
  # matches only empty lines
  qr/^\s*\z/;
  }

sub _match_multi_line_comment
  {
  # match a multi line comment

  # /* * comment * */
  qr#^\s*/\*.*?\*/\s*#;
  }

sub _match_optional_multi_line_comment
  {
  # match a multi line comment

  # "/* * comment * */" or /* a */ /* b */ or ""
  qr#(?:(?:\s*/\*.*?\*/\s*)*|\s+)#;
  }

sub _match_classname
  {
  # Return a regexp that matches something like classname 1: "foo"
  my $self = shift;

  qr/^\s*classname\s([0-9]+)\s*:\s*"((\\"|[^"])*)"/;
  }

sub _match_node
  {
  # Return a regexp that matches a node at the start of the buffer
  my $self = shift;

  my $attr = $self->_match_attributes();

  # Examples: "node: { title: "a" }"
  qr/^\s*node:\s*$attr/;
  }

sub _match_edge
  {
  # Matches an edge at the start of the buffer
  my $self = shift;

  my $attr = $self->_match_attributes();

  # Examples: "edge: { sourcename: "a" targetname: "b" }"
  #           "backedge: { sourcename: "a" targetname: "b" }"
  qr/^\s*(|near|bentnear|back)edge:\s*$attr/;
  }

sub _match_single_attribute
  {

  qr/\s*(	energetic\s\w+			# "energetic attraction" etc.
		|
		\w+ 				# a word
		|
		border\s(?:x|y)			# "border x" or "border y"
		|
		colorentry\s+[0-9]{1,2}		# colorentry
	)\s*:\s*
    (
      "(?:\\"|[^"])*"				# "foo"
    |
      [0-9]{1,3}\s+[0-9]{1,3}\s+[0-9]{1,3}	# "128 128 64" for color entries
    |
      \{[^\}]+\}				# or {..}
    |
      [^<][^,\]\}\n\s;]*			# or simple 'fooobar'
    )
    \s*/x;					# possible trailing whitespace
  }

sub _match_class_attribute
  {
  # match something like "edge.color: 10"

  qr/\s*(edge|node)\.(\w+)\s*:\s*	# the attribute name (label:")
    (
      "(?:\\"|[^"])*"		# "foo"
    |
      [^<][^,\]\}\n\s]*		# or simple 'fooobar'
    )
    \s*/x;			# possible whitespace
  }

sub _match_attributes
  {
  # return a regexp that matches something like " { color=red; }" and returns
  # the inner text without the {}

  my $qr_att = _match_single_attribute();
  my $qr_cmt = _match_multi_line_comment();
 
  qr/\s*\{\s*((?:$qr_att|$qr_cmt)*)\s*\}/;
  }

sub _match_graph_attribute
  {
  # return a regexp that matches something like " color: red " for attributes
  # that apply to a graph/subgraph
  qr/^\s*(
    (
     colorentry\s+[0-9]{1,2}:\s+[0-9]+\s+[0-9]+\s+[0-9]+
     |
     (?!(node|edge|nearedge|bentnearedge|graph))	# not one of these
     \w+\s*:\s*("(?:\\"|[^"])*"|[^\n\s]+)
    )
   )([\n\s]\s*|\z)/x;
  }

sub _clean_attributes
  {
  my ($self,$text) = @_;

  $text =~ s/^\s*\{\s*//;		# remove left-over "{" and spaces
  $text =~ s/\s*;?\s*\}\s*\z//;		# remove left-over "}" and spaces

  $text;
  }

sub _match_group_end
  {
  # return a regexp that matches something like " }" at the beginning
  qr/^\s*\}\s*/;
  }

sub _match_group_start
  {
  # return a regexp that matches something like "graph {" at the beginning
  qr/^\s*graph:\s+\{\s*/;
  }

sub _clean_line
  { 
  # do some cleanups on a line before handling it
  my ($self,$line) = @_;

  chomp($line);

  # collapse white space at start
  $line =~ s/^\s+//;

  if ($self->{_in_vcg_multi_line_label})
    {
    if ($line =~ /\"[^\"]*\z/)
      {
      # '"\n'
      $self->{_in_vcg_multi_line_label} = 0;
      # restore the match stack
      $self->{match_stack} = $self->{_match_stack};
      delete $self->{_match_stack};
      }
    else
      {
      # hack: convert "a" to \"a\" to fix faulty inputs
      $line =~ s/([^\\])\"/$1\\\"/g;
      }
    }
  # a line ending in 'label: "...\n' means a multi-line label
  elsif ($line =~ /(^|\s)label:\s+\"[^\"]*\z/)
    {
    $self->{_in_vcg_multi_line_label} = 1;
    # swap out the match stack since we just wait for the end of the label
    $self->{_match_stack} = $self->{match_stack};
    delete $self->{match_stack};
    }

  $line;
  }

sub _line_insert
  {
  # What to insert between two lines.
  my ($self) = @_;

  print STDERR "in multiline\n" if $self->{_in_vcg_multi_line_label} && $self->{debug};
  # multiline labels => '\n'
  return '\\n' if $self->{_in_vcg_multi_line_label};

  # the default is ' '
  ' ';
  }

#############################################################################

sub _new_scope
  {
  # create a new scope, with attributes from current scope
  my ($self, $is_group) = @_;

  my $scope = {};

  if (@{$self->{scope_stack}} > 0)
    {
    my $old_scope = $self->{scope_stack}->[-1];

    # make a copy of the old scope's attribtues
    for my $t (keys %$old_scope)
      {
      next if $t =~ /^_/;
      my $s = $old_scope->{$t};
      $scope->{$t} = {} unless ref $scope->{$t}; my $sc = $scope->{$t};
      for my $k (keys %$s)
        {
        # skip things like "_is_group"
        $sc->{$k} = $s->{$k} unless $k =~ /^_/;
        }
      }
    }
  $scope->{_is_group} = 1 if defined $is_group;

  push @{$self->{scope_stack}}, $scope;

  $scope;
  }

sub _edge_style
  {
  # To convert "--" or "->" we simple do nothing, since the edge style in
  # VCG can only be set via the attributes (if at all)
  my ($self, $ed) = @_;

  'solid';
  }

sub _build_match_stack
  {
  my $self = shift;

  my $qr_cn    = $self->_match_classname();
  my $qr_node  = $self->_match_node();
  my $qr_cmt   = $self->_match_multi_line_comment();
  my $qr_ocmt  = $self->_match_optional_multi_line_comment();
  my $qr_attr  = $self->_match_attributes();
  my $qr_gatr  = $self->_match_graph_attribute();
  my $qr_oatr  = $self->_match_optional_attributes();
  my $qr_edge  = $self->_match_edge();
  my $qr_class = $self->_match_class_attribute();

  my $qr_group_end   = $self->_match_group_end();
  my $qr_group_start = $self->_match_group_start();

  # "graph: {"
  $self->_register_handler( $qr_group_start,
    sub
      {
      my $self = shift;

      # the main graph
      if (@{$self->{scope_stack}} == 0)
        {
        print STDERR "# Parser: found main graph\n" if $self->{debug};
	$self->{_vcg_graph_name} = 'unnamed'; 
	$self->_new_scope(1);
        }
      else
	{
        print STDERR "# Parser: found subgraph\n" if $self->{debug};
	# a new subgraph
        push @{$self->{group_stack}}, $self->_new_group();
	}
      1;
      } );

  # graph or subgraph end "}"
  $self->_register_handler( $qr_group_end,
    sub
      {
      my $self = shift;

      print STDERR "# Parser: found end of (sub-)graph\n" if $self->{debug};
      
      my $scope = pop @{$self->{scope_stack}};
      return $self->parse_error(0) if !defined $scope;

      1;
      } );

  # classname 1: "foo"
  $self->_register_handler( $qr_cn,
    sub {
      my $self = shift;
      my $class = $1; my $name = $2;

      print STDERR "#  Found classname '$name' for class '$class'\n" if $self->{debug} > 1;

      $self->{_graph}->{_vcg_class_names}->{$class} = $name;
      1;
      } );

  # node: { ... }
  $self->_register_handler( $qr_node,
    sub {
      my $self = shift;
      my $att = $self->_parse_attributes($1 || '', 'node', NO_MULTIPLES );
      return undef unless defined $att;		# error in attributes?

      my $name = $att->{title}; delete $att->{title};

      print STDERR "#  Found node with name $name\n" if $self->{debug} > 1;

      my $node = $self->_new_node($self->{_graph}, $name, $self->{group_stack}, $att, []);

      # set attributes from scope
      my $scope = $self->{scope_stack}->[-1] || {};
      $node->set_attributes ($scope->{node}) if keys %{$scope->{node}} != 0;

      # override with local attributes
      $node->set_attributes ($att) if keys %$att != 0;
      1;
      } );

  # "edge: { ... }"
  $self->_register_handler( $qr_edge,
    sub {
      my $self = shift;
      my $type = $1 || 'edge';
      my $txt = $2 || '';
      $type = "edge" if $type =~ /edge/;	# bentnearedge => edge
      my $att = $self->_parse_attributes($txt, 'edge', NO_MULTIPLES );
      return undef unless defined $att;		# error in attributes?

      my $from = $att->{source}; delete $att->{source};
      my $to = $att->{target}; delete $att->{target};

      print STDERR "#  Found edge ($type) from $from to $to\n" if $self->{debug} > 1;

      my $edge = $self->{_graph}->add_edge ($from, $to);

      # set attributes from scope
      my $scope = $self->{scope_stack}->[-1] || {};
      $edge->set_attributes ($scope->{edge}) if keys %{$scope->{edge}} != 0;

      # override with local attributes
      $edge->set_attributes ($att) if keys %$att != 0;

      1;
      } );

  # color: red (for graphs or subgraphs)
  $self->_register_attribute_handler($qr_gatr, 'parent');

  # edge.color: 10
  $self->_register_handler( $qr_class,
    sub {
      my $self = shift;
      my $type = $1;
      my $name = $2;
      my $val = $3;

      print STDERR "#  Found color definition $type $name $val\n" if $self->{debug} > 2;

      my $att = $self->_remap_attributes( { $name => $val }, $type, $self->_remap());

      # store the attributes in the current scope
      my $scope = $self->{scope_stack}->[-1];
      $scope->{$type} = {} unless ref $scope->{$type};
      my $s = $scope->{$type};

      for my $k (keys %$att)
        {
        $s->{$k} = $att->{$k};
        }

      #$self->{_graph}->set_attributes ($type, $att);
      1;
      });

  # remove multi line comments /* comment */
  $self->_register_handler( $qr_cmt, undef );
  
  # remove single line comment // comment
  $self->_register_handler( qr/^\s*\/\/.*/, undef );

  $self;
  }

sub _new_node
  {
  # add a node to the graph, overridable by subclasses
  my ($self, $graph, $name, $group_stack, $att, $stack) = @_;

#  print STDERR "add_node $name\n";

  my $node = $graph->node($name);
 
  if (!defined $node)
    {
    $node = $graph->add_node($name);		# add

    # apply attributes from the current scope (only for new nodes)
    my $scope = $self->{scope_stack}->[-1];
    return $self->error("Scope stack is empty!") unless defined $scope;
  
    my $is_group = $scope->{_is_group};
    delete $scope->{_is_group};
    $node->set_attributes($scope->{node});
    $scope->{_is_group} = $is_group if $is_group;

    my $group = $self->{group_stack}->[-1];

    $node->add_to_group($group) if $group;
    }

  $node;
  }

#############################################################################
# attribute remapping

# undef => drop that attribute
# not listed attributes are simple copied unmodified

my $vcg_remap = {
  'node' => {
    iconfile => 'x-vcg-iconfile',
    info1 => 'x-vcg-info1',
    info2 => 'x-vcg-info2',
    info3 => 'x-vcg-info3',
    invisible => \&_invisible_from_vcg,
    importance => 'x-vcg-importance',
    focus => 'x-vcg-focus',
    margin => 'x-vcg-margin',
    textmode => \&_textmode_from_vcg,
    textcolor => \&_node_color_from_vcg,
    color => \&_node_color_from_vcg,
    bordercolor => \&_node_color_from_vcg,
    level => 'rank',
    horizontal_order => \&_horizontal_order_from_vcg,
    shape => \&_vcg_node_shape,
    vertical_order => \&_vertical_order_from_vcg,
    },

  'edge' => {
    anchor => 'x-vcg-anchor',
    right_anchor => 'x-vcg-right_anchor',
    left_anchor => 'x-vcg-left_anchor',
    arrowcolor => 'x-vcg-arrowcolor',
    arrowsize => 'x-vcg-arrowsize',
    # XXX remap this
    arrowstyle => 'x-vcg-arrowstyle',
    backarrowcolor => 'x-vcg-backarrowcolor',
    backarrowsize => 'x-vcg-backarrowsize',
    backarrowstyle => 'x-vcg-backarrowstyle',
    class => \&_edge_class_from_vcg,
    color => \&_edge_color_from_vcg,
    horizontal_order => 'x-vcg-horizontal_order',
    linestyle => 'style',
    priority => 'x-vcg-priority',
    source => 'source',
    sourcename => 'source',
    target => 'target',
    targetname => 'target',
    textcolor => \&_edge_color_from_vcg,
    thickness => 'x-vcg-thickness', 		# remap to broad etc.
    },

  'graph' => {
    color => \&_node_color_from_vcg,
    bordercolor => \&_node_color_from_vcg,
    textcolor => \&_node_color_from_vcg,

    x => 'x-vcg-x',
    y => 'x-vcg-y',
    xmax => 'x-vcg-xmax',
    ymax => 'x-vcg-ymax',
    xspace => 'x-vcg-xspace',
    yspace => 'x-vcg-yspace',
    xlspace => 'x-vcg-xlspace',
    ylspace => 'x-vcg-ylspace',
    xbase => 'x-vcg-xbase',
    ybase => 'x-vcg-ybase',
    xlraster => 'x-vcg-xlraster',
    xraster => 'x-vcg-xraster',
    yraster => 'x-vcg-yraster',

    amax => 'x-vcg-amax',
    bmax => 'x-vcg-bmax',
    cmax => 'x-vcg-cmax',
    cmin => 'x-vcg-cmin',
    smax => 'x-vcg-smax',
    pmax => 'x-vcg-pmax',
    pmin => 'x-vcg-pmin',
    rmax => 'x-vcg-rmax',
    rmin => 'x-vcg-rmin',

    splines => 'x-vcg-splines',
    focus => 'x-vcg-focus',
    hidden => 'x-vcg-hidden',
    horizontal_order => 'x-vcg-horizontal_order',
    iconfile => 'x-vcg-iconfile',
    inport_sharing => \&_inport_sharing_from_vcg,
    importance => 'x-vcg-importance',
    ignore_singles => 'x-vcg-ignore_singles',
    invisible => 'x-vcg-invisible',
    info1 => 'x-vcg-info1',
    info2 => 'x-vcg-info2',
    info3 => 'x-vcg-info3',
    infoname1 => 'x-vcg-infoname1',
    infoname2 => 'x-vcg-infoname2',
    infoname3 => 'x-vcg-infoname3',
    level => 'x-vcg-level',
    loc => 'x-vcg-loc',
    layout_algorithm => 'x-vcg-layout_algorithm',
    # also allow this variant:
    layoutalgorithm => 'x-vcg-layout_algorithm',
    layout_downfactor => 'x-vcg-layout_downfactor',
    layout_upfactor => 'x-vcg-layout_upfactor',
    layout_nearfactor => 'x-vcg-layout_nearfactor',
    linear_segments => 'x-vcg-linear_segments',
    margin => 'x-vcg-margin',
    manhattan_edges => \&_manhattan_edges_from_vcg,
    near_edges => 'x-vcg-near_edges',
    nearedges => 'x-vcg-nearedges',
    node_alignment => 'x-vcg-node_alignment',
    port_sharing => \&_port_sharing_from_vcg,
    priority_phase => 'x-vcg-priority_phase',
    outport_sharing => \&_outport_sharing_from_vcg,
    shape => 'x-vcg-shape',
    smanhattan_edges => 'x-vcg-smanhattan_edges',
    state => 'x-vcg-state',
    splines => 'x-vcg-splines',
    splinefactor => 'x-vcg-splinefactor',
    spreadlevel => 'x-vcg-spreadlevel',

    title => 'label',
    textmode => \&_textmode_from_vcg,
    useractioncmd1 => 'x-vcg-useractioncmd1',
    useractioncmd2 => 'x-vcg-useractioncmd2',
    useractioncmd3 => 'x-vcg-useractioncmd3',
    useractioncmd4 => 'x-vcg-useractioncmd4',
    useractionname1 => 'x-vcg-useractionname1',
    useractionname2 => 'x-vcg-useractionname2',
    useractionname3 => 'x-vcg-useractionname3',
    useractionname4 => 'x-vcg-useractionname4',
    vertical_order => 'x-vcg-vertical_order',

    display_edge_labels => 'x-vcg-display_edge_labels',
    edges => 'x-vcg-edges',
    nodes => 'x-vcg-nodes',
    icons => 'x-vcg-icons',
    iconcolors => 'x-vcg-iconcolors',
    view => 'x-vcg-view',
    subgraph_labels => 'x-vcg-subgraph_labels',
    arrow_mode => 'x-vcg-arrow_mode',
    arrowmode => 'x-vcg-arrowmode',
    crossing_optimization => 'x-vcg-crossing_optimization',
    crossing_phase2 => 'x-vcg-crossing_phase2',
    crossing_weight => 'x-vcg-crossing_weight',
    equal_y_dist => 'x-vcg-equal_y_dist',
    equalydist => 'x-vcg-equalydist',
    finetuning => 'x-vcg-finetuning',
    fstraight_phase => 'x-vcg-fstraight_phase',
    straight_phase => 'x-vcg-straight_phase',
    import_sharing => 'x-vcg-import_sharing',
    late_edge_labels => 'x-vcg-late_edge_labels',
    treefactor => 'x-vcg-treefactor',
    orientation => \&_orientation_from_vcg,

    attraction => 'x-vcg-attraction',
    'border x' => 'x-vcg-border-x',
    'border y' => 'x-vcg-border-y',
    'energetic' => 'x-vcg-energetic',
    'energetic attraction' => 'x-vcg-energetic-attraction',
    'energetic border' => 'x-vcg-energetic-border',
    'energetic crossing' => 'x-vcg-energetic-crossing',
    'energetic gravity' => 'x-vcg-energetic gravity',
    'energetic overlapping' => 'x-vcg-energetic overlapping',
    'energetic repulsion' => 'x-vcg-energetic repulsion',
    fdmax => 'x-vcg-fdmax',
    gravity => 'x-vcg-gravity',

    magnetic_field1 => 'x-vcg-magnetic_field1',
    magnetic_field2 => 'x-vcg-magnetic_field2',
    magnetic_force1 => 'x-vcg-magnetic_force1',
    magnetic_force2 => 'x-vcg-magnetic_force2',
    randomfactor => 'x-vcg-randomfactor',
    randomimpulse => 'x-vcg-randomimpulse',
    randomrounds => 'x-vcg-randomrounds',
    repulsion => 'x-vcg-repulsion',
    tempfactor => 'x-vcg-tempfactor',
    tempmax => 'x-vcg-tempmax',
    tempmin => 'x-vcg-tempmin'.
    tempscheme => 'x-vcg-tempscheme'.
    temptreshold => 'x-vcg-temptreshold',

    dirty_edge_labels => 'x-vcg-dirty_edge_labels',
    fast_icons => 'x-vcg-fast_icons',

    },

  'group' => {
    # graph attributes will be added here automatically
    title => \&_group_name_from_vcg,
    status => 'x-vcg-status',
    },

  'all' => {
    loc => 'x-vcg-loc',
    folding => 'x-vcg-folding',
    scaling => 'x-vcg-scaling',
    shrink => 'x-vcg-shrink',
    stretch => 'x-vcg-stretch',
    width => 'x-vcg-width',
    height => 'x-vcg-height',
    fontname => 'font',
    },
  };

  {
  # add all graph attributes to group, too
  my $group = $vcg_remap->{group};
  my $graph = $vcg_remap->{graph};
  for my $k (keys %$graph)
    {
    $group->{$k} = $graph->{$k};
    }
  }

sub _remap { $vcg_remap; }

my $vcg_edge_color_remap = {
  textcolor => 'labelcolor',
  };

my $vcg_node_color_remap = {
  textcolor => 'color',
  color => 'fill',
  };

sub _vertical_order_from_vcg
  {
  # remap "vertical_order: 5" to "rank: 5"
  my ($graph, $name, $value) = @_;

  my $rank = $value;
  # insert a really really high rank
  $rank = '1000000' if $value eq 'maxdepth';

  # save the original value, too
  ('x-vcg-vertical_order', $value, 'rank', $rank);
  }

sub _horizontal_order_from_vcg
  {
  # remap "horizontal_order: 5" to "rank: 5"
  my ($graph, $name, $value) = @_;

  my $rank = $value;
  # insert a really really high rank
  $rank = '1000000' if $value eq 'maxdepth';

  # save the original value, too
  ('x-vcg-horizontal_order', $value, 'rank', $rank);
  }

sub _invisible_from_vcg
  {
  # remap "invisible: yes" to "shape: invisible"
  my ($graph, $name, $value) = @_;

  return (undef,undef) if $value ne 'yes';

  ('shape', 'invisible');
  }

sub _manhattan_edges_from_vcg
  {
  # remap "manhattan_edges: yes" for graphs
  my ($graph, $name, $value) = @_;

  if ($value eq 'yes')
    {
    $graph->set_attribute('edge','start','front');
    $graph->set_attribute('edge','end','back');
    }
  # store the value for proper VCG output
  ('x-vcg-' . $name, $value);
  }

sub _textmode_from_vcg
  {
  # remap "textmode: left_justify" to "align: left;"
  my ($graph, $name, $align) = @_;

  $align =~ s/_.*//;	# left_justify => left	

  ('align', lc($align));
  }

sub _edge_color_from_vcg
  {
  # remap "darkyellow" to "rgb(128 128 0)"
  my ($graph, $name, $color) = @_;

#  print STDERR "edge $name $color\n";
#  print STDERR ($vcg_edge_color_remap->{$name} || $name, " ", $vcg_color_by_name->{$color} || $color), "\n";

  my $c = $vcg_color_by_name->{$color} || $color;
  $c = $graph->{_vcg_color_map}->[$c] if $c =~ /^[0-9]+\z/ && $c < 256;

  ($vcg_edge_color_remap->{$name} || $name, $c);
  }

sub _edge_class_from_vcg
  {
  # remap "1" to "edgeclass1" to create a valid class name
  my ($graph, $name, $class) = @_;

  $class = $graph->{_vcg_class_names}->{$class} || ('edgeclass' . $class) if $class =~ /^[0-9]+\z/;
  #$class = 'edgeclass' . $class if $class !~ /^[a-zA-Z]/;

  ('class', $class);
  }

my $vcg_orientation = {
  top_to_bottom => 'south',
  bottom_to_top => 'north',
  left_to_right => 'east',
  right_to_left => 'west',
  };

sub _orientation_from_vcg
  {
  my ($graph, $name, $value) = @_;

  ('flow', $vcg_orientation->{$value} || 'south');
  }

sub _port_sharing_from_vcg
  {
  # if we see this, add autojoin/autosplit
  my ($graph, $name, $value) = @_;

  $value = ($value =~ /yes/i) ? 'yes' : 'no';
 
  ('autojoin', $value, 'autosplit', $value);
  }

sub _inport_sharing_from_vcg
  {
  # if we see this, add autojoin/autosplit
  my ($graph, $name, $value) = @_;

  $value = ($value =~ /yes/i) ? 'yes' : 'no';
 
  ('autojoin', $value);
  }

sub _outport_sharing_from_vcg
  {
  # if we see this, add autojoin/autosplit
  my ($graph, $name, $value) = @_;

  $value = ($value =~ /yes/i) ? 'yes' : 'no';
 
  ('autosplit', $value);
  }

sub _node_color_from_vcg
  {
  # remap "darkyellow" to "rgb(128 128 0)"
  my ($graph, $name, $color) = @_;

  my $c = $vcg_color_by_name->{$color} || $color;
  $c = $graph->{_vcg_color_map}->[$c] if $c =~ /^[0-9]+\z/ && $c < 256;

  ($vcg_node_color_remap->{$name} || $name, $c);
  }

my $shapes = {
  box => 'rect',
  rhomb => 'diamond',
  triangle => 'triangle',
  ellipse => 'ellipse',
  circle => 'circle',
  hexagon => 'hexagon',
  trapeze => 'trapezium',
  uptrapeze => 'invtrapezium',
  lparallelogram => 'invparallelogram',
  rparallelogram => 'parallelogram',
  };

sub _vcg_node_shape
  {
  my ($self, $name, $shape) = @_;

  my @rc;
  my $s = lc($shape);

  # map the name to what Graph::Easy expects (ellipse stays as ellipse but
  # everything unknown gets converted to rect)
  $s = $shapes->{$s} || 'rect';

  (@rc, $name, $s);
  }

sub _group_name_from_vcg
  {
  my ($self, $attr, $name, $object) = @_;

  print STDERR "# Renaming anon group '$object->{name}' to '$name'\n"
	if $self->{debug} > 0;

  $self->rename_group($object, $name);

  # name was set, so drop the "title: name" pair
  (undef, undef);
  }

#############################################################################

sub _remap_attributes
  {
  my ($self, $att, $object, $r) = @_;

#  print STDERR "# Remapping attributes\n";
#    use Data::Dumper; print Dumper($att);

  # handle the "colorentry 00" entries:
  for my $key (keys %$att)
    {
    if ($key =~ /^colorentry\s+([0-9]{1,2})/)
      {
      # put the color into the current color map
      $self->_vcg_color_map_entry($1, $att->{$key});
      delete $att->{$key};
      next; 
      }

    # remap \fi065 to 'A'
    $att->{$key} =~ s/(\x0c|\\f)i([0-9]{3})/ decode('iso-8859-1', chr($2)); /eg;

    # XXX TDOO: support inline colorations
    # remap \f65 to ''
    $att->{$key} =~ s/(\x0c|\\f)([0-9]{2})//g;

    # remap \c09 to color 09: TODO for now remove
    $att->{$key} =~ s/(\x0c|\\f)([0-9]{2})//g;

    # XXX TODO: support real hor lines
    # insert a fake <HR>
    $att->{$key} =~ s/(\x0c|\\f)-/\\c ---- \\n /g;

    }
  $self->SUPER::_remap_attributes($att,$object,$r);
  }

#############################################################################

sub _parser_cleanup
  {
  # After initial parsing, do cleanup.
  my ($self) = @_;

  my $g = $self->{_graph};
  $g->{_warn_on_unknown_attributes} = 0;	# reset to die again

  delete $g->{_vcg_color_map};
  delete $g->{_vcg_class_names};

  $self;
  }

1;
__END__

=head1 NAME

Graph::Easy::Parser::VCG - Parse VCG or GDL text into Graph::Easy

=head1 SYNOPSIS

        # creating a graph from a textual description

        use Graph::Easy::Parser::VCG;
        my $parser = Graph::Easy::Parser::VCG->new();

        my $graph = $parser->from_text(
                "graph: { \n" .
	 	"	node: { title: "Bonn" }\n" .
	 	"	node: { title: "Berlin" }\n" .
	 	"	edge: { sourcename: "Bonn" targetname: "Berlin" }\n" .
		"}\n"
        );
        print $graph->as_ascii();

	print $parser->from_file('mygraph.vcg')->as_ascii();

=head1 DESCRIPTION

C<Graph::Easy::Parser::VCG> parses the text format from the VCG or GDL
(Graph Description Language) use by tools like GCC and AiSee, and
constructs a C<Graph::Easy> object from it.

The resulting object can then be used to layout and output the graph
in various formats.

=head2 Output

The output will be a L<Graph::Easy|Graph::Easy> object (unless overrriden
with C<use_class()>), see the documentation for Graph::Easy what you can do
with it.

=head2 Attributes

Attributes will be remapped to the proper Graph::Easy attribute names and
values, as much as possible.

Anything else will be converted to custom attributes starting with "x-vcg-".
So "dirty_edge_labels: yes" will become "x-vcg-dirty_edge_labels: yes".

=head1 METHODS

C<Graph::Easy::Parser::VCG> supports the same methods
as its parent class C<Graph::Easy::Parser>:

=head2 new()

	use Graph::Easy::Parser::VCG;
	my $parser = Graph::Easy::Parser::VCG->new();

Creates a new parser object. There are two valid parameters:

	debug
	fatal_errors

Both take either a false or a true value.

	my $parser = Graph::Easy::Parser::VCG->new( debug => 1 );
	$parser->from_text('graph: { }');

=head2 reset()

	$parser->reset();

Reset the status of the parser, clear errors etc. Automatically called
when you call any of the C<from_XXX()> methods below.

=head2 use_class()

	$parser->use_class('node', 'Graph::Easy::MyNode');

Override the class to be used to constructs objects while parsing.

See L<Graph::Easy::Parser> for further information.

=head2 from_text()

	my $graph = $parser->from_text( $text );

Create a L<Graph::Easy|Graph::Easy> object from the textual description in C<$text>.

Returns undef for error, you can find out what the error was
with L<error()>.

This method will reset any previous error, and thus the C<$parser> object
can be re-used to parse different texts by just calling C<from_text()>
multiple times.

=head2 from_file()

	my $graph = $parser->from_file( $filename );
	my $graph = Graph::Easy::Parser::VCG->from_file( $filename );

Creates a L<Graph::Easy|Graph::Easy> object from the textual description in the file
C<$filename>.

The second calling style will create a temporary parser object,
parse the file and return the resulting C<Graph::Easy> object.

Returns undef for error, you can find out what the error was
with L<error()> when using the first calling style.

=head2 error()

	my $error = $parser->error();

Returns the last error, or the empty string if no error occured.

=head2 parse_error()

	$parser->parse_error( $msg_nr, @params);

Sets an error message from a message number and replaces embedded
templates like C<##param1##> with the passed parameters.

=head1 CAVEATS

The parser has problems with the following things:

=over 12

=item attributes

Some attributes are B<not> remapped properly to what Graph::Easy expects, thus
losing information, either because Graph::Easy doesn't support this feature
yet, or because the mapping is incomplete.

=item comments

Comments written in the source code itself are discarded. If you want to have
comments on the graph, clusters, nodes or edges, use the attribute C<comment>.
These are correctly read in and stored, and then output into the different
formats, too.

=back

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>, L<Graph::Write::VCG>.

=head1 AUTHOR

Copyright (C) 2005 - 2008 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut

#############################################################################
# Render Nodes/Edges/Cells as ASCII/Unicode box drawing art
#
# (c) by Tels 2004-2007. Part of Graph::Easy
#############################################################################

package Graph::Easy::As_ascii;

$VERSION = '0.22';

use utf8;

#############################################################################
#############################################################################

package Graph::Easy::Edge::Cell;

use strict;

my $edge_styles = [ 
  {
  # style            hor, ver,   cross,	corner (SE, SW, NE, NW)
  'solid'	 => [ '--',  "|", '+', '+','+','+','+' ],	# simple line
  'double'	 => [ '==',  "H", "#", '#','#','#','#' ],	# double line
  'double-dash'	 => [ '= ',  '"', "#", '#','#','#','#' ],	# double dashed line
  'dotted'	 => [ '..',  ":", ':', '.','.','.','.' ],	# dotted
  'dashed'	 => [ '- ',  "'", '+', '+','+','+','+' ],	# dashed
  'dot-dash'	 => [ '.-',  "!", '+', '+','+','+','+' ],	# dot-dash
  'dot-dot-dash' => [ '..-', "!", '+', '+','+','+','+' ],	# dot-dot-dash
  'wave' 	 => [ '~~',  "}", '+', '*','*','*','*' ],	# wave
  'bold' 	 => [ '##',  "#", '#', '#','#','#','#' ],	# bold
  'bold-dash' 	 => [ '# ',  "#", '#', '#','#','#','#' ],	# bold-dash
  'wide' 	 => [ '##',  "#", '#', '#','#','#','#' ],	# wide
  'broad' 	 => [ '##',  "#", '#', '#','#','#','#' ],	# broad
  },
  {
  # style            hor, ver,   	    cross,     corner (SE, SW, NE, NW)
  'solid'	 => [ '─', '│', '┼',  '┌', '┐', '└', '┘' ],
  'double'	 => [ '═', '║', '╬',  '╔', '╗', '╚', '╝' ],
  'double-dash'	 => [ '═'.' ', '∥', '╬',  '╔', '╗', '╚', '╝' ], # double dashed
  'dotted'	 => [ '·', ':',     '┼',  '┌', '┐', '└', '┘' ], # dotted
  'dashed'	 => [ '╴', '╵', '┘',  '┌', '┐', '╵', '┘' ], # dashed
  'dot-dash'	 => [ '·'.'-',  "!",   '┼',  '┌', '┐', '└', '┘' ], # dot-dash
  'dot-dot-dash' => [ ('·' x 2).'-', "!",  '┼',  '┌', '┐', '└', '┘' ], # dot-dot-dash
  'wave' 	 => [ '∼', '≀',     '┼',  '┌', '┐', '└', '┘' ], # wave
  'bold' 	 => [ '━', '┃', '╋',  '┏', '┓', '┗', '┛' ], # bold
  'bold-dash' 	 => [ '━'.' ', '╻', '╋',  '┏', '┓', '┗', '┛' ], # bold-dash
  'broad' 	 => [ '▬', '▮', '█',  '█', '█', '█', '█' ], # wide
  'wide' 	 => [ '█', '█', '█',  '█', '█', '█', '█' ], # broad

# these two make it nec. to support multi-line styles for the vertical edge pieces
#  'broad-dash' 	 => [ '◼', '◼', '◼',  '◼', '◼', '◼', '◼' ], # broad-dash
#  'wide-dash' 	 => [ ('█'x 2) .'  ', '█', '█',  '█', '█', '█', '█' ], # wide-dash
  },
  ];

sub _edge_style
  {
  my ($self, $st) = @_;

  my $g = $self->{graph}->{_ascii_style} || 0;
  $st = $self->{style} unless defined $st;

  $edge_styles->[$g]->{ $st };
  }

  #    |       |        |        |        :        }       |     
  # ===+=== ###+### ....!.... ~~~+~~~ ----+---  ...+... .-.+.-.-
  #    |       |        |        |        :        {       |   

my $cross_styles = [
  # normal cross 
  [
    {
    'boldsolid' 	=> '┿',
    'solidbold' 	=> '╂',
    'doublesolid' 	=> '╪',
    'soliddouble' 	=> '╫',
    'dashedsolid' 	=> '┤',
    'soliddashed' 	=> '┴',
    'doubledashed' 	=> '╧',
    'dasheddouble' 	=> '╢',
    },
    {
    'boldsolid'		=> '+',  
    'dashedsolid'	=> '+',  
    'dottedsolid'	=> '!',
    'dottedwave'	=> '+',  
    'doublesolid'	=> '+',  
    'dot-dashsolid'	=> '+',  
    'dot-dot-dashsolid'	=> '+',  
    'soliddotted'	=> '+',  
    'solidwave'		=> '+',  
    'soliddashed'	=> '+',  
    'soliddouble'	=> 'H',  
    'wavesolid'		=> '+',
    },
  ],
  undef,	# HOR, cannot happen
  undef,	# VER, cannot happen
  undef,
  undef,
  undef,
  undef,
  # S_E_W -+-
  #        |
  [
    {
    'solidsolid'		=> '┬',  
    'boldbold'			=> '┳',  
    'doubledouble'		=> '╦',  
    'dasheddashed'		=> '╴',  
    'dotteddotted'		=> '·',  
    },
  ],
  # N_E_W  |
  #       -+-
  [ 
    {
    'solidsolid'		=> '┴',  
    'boldbold'			=> '┻',  
    'doubledouble'		=> '╩',  
    'dotteddotted'		=> '·',  
    },
  ],
  # E_N_S  |
  #        +-
  #        |
  [ 
    {
    'solidsolid'		=> '├',  
    'boldbold'			=> '┣',  
    'doubledouble'		=> '╠',  
    'dotteddotted'		=> ':',  
    },
  ],
  # W_N_S  |
  #       -+
  #        |
  [ 
    {
    'solidsolid'		=> '┤',  
    'boldbold'			=> '┫',  
    'doubledouble'		=> '╣',  
    'dotteddotted'		=> ':',  
    },
  ] ];

sub _arrow_style
  {
  my $self = shift;

  my $edge = $self->{edge};

  my $as = $edge->attribute('arrowstyle');
  $as = 'none' if $edge->{undirected};
  $as;
  }

sub _arrow_shape
  {
  my $self = shift;

  my $edge = $self->{edge};

  my $as = $edge->attribute('arrowshape');
  $as;
  }

sub _cross_style
  {
  my ($self, $st, $corner_type) = @_;

  my $g = $self->{graph}->{_ascii_style} || 0;

  # 0 => 1, 1 => 0
  $g = 1 - $g;

  # for ASCII, one style fist all (e.g a joint has still "+" as corner)
  $corner_type = 0 unless defined $corner_type;
  $corner_type = 0 if $g == 1;

  $cross_styles->[$corner_type]->[$g]->{ $st };
  }

sub _insert_label
  {
  my ($self, $fb, $xs, $ys, $ws, $hs, $align_ver) = @_;

  my $align = $self->{edge}->attribute('align');
  
  my ($lines,$aligns) = $self->_aligned_label($align);

  $ys = $self->{h} - scalar @$lines + $ys if $ys < 0; 

  $ws ||= 0; $hs ||= 0;
  my $w = $self->{w} - $ws - $xs;
  my $h = $self->{h} - $hs - $ys;

  $self->_printfb_aligned ($fb, $xs, $ys, $w, $h, $lines, $aligns, $align_ver);
  }

sub _draw_hor
  {
  # draw a HOR edge piece
  my ($self, $fb) = @_;

  my $style = $self->_edge_style();
  
  my $w = $self->{w};
  # '-' => '-----', '.-' => '.-.-.-'
  # "(2 + ... )" to get space for the offset
  my $len = length($style->[0]); 
  my $line = $style->[0] x (2 + $w / $len); 

  # '.-.-.-' => '-.-.-' if $x % $ofs == 1 (e.g. on odd positions)
  my $ofs = $self->{rx} % $len;
  my $type = ($self->{type} & (~EDGE_MISC_MASK));
  substr($line,0,$ofs) = '' if $ofs != 0
    && ($type != EDGE_SHORT_E && $type != EDGE_SHORT_W);

  $line = substr($line, 0, $w) if length($line) > $w;

  # handle start/end point

  my $flags = $self->{type} & EDGE_FLAG_MASK;

  my $as = $self->_arrow_style();
  my $ashape; $ashape = $self->_arrow_shape() if $as ne 'none';

  my $x = 0;				# offset for the edge line
  my $xs = 1;				# offset for the edge label
  my $xr = 0;				# right offset for label
  if (($flags & EDGE_START_W) != 0)
    {
    $x++; chop($line);			# ' ---'
    $xs++;
    }
  if (($flags & EDGE_START_E) != 0)
    {
    chop($line);			# '--- '
    }

  if (($flags & EDGE_END_E) != 0)
    {
    # '--> '
    chop($line);
    substr($line,-1,1) = $self->_arrow($as, ARROW_RIGHT, $ashape) if $as ne 'none';
    $xr++;
    }
  if (($flags & EDGE_END_W) != 0)
    {
    # ' <--'
    substr($line,0,1) = ' ' if $as eq 'none';
    substr($line,0,2) = ' ' . $self->_arrow($as, ARROW_LEFT, $ashape) if $as ne 'none';
    $xs++;
    }

  $self->_printfb_line ($fb, $x, $self->{h} - 2, $line);

  $self->_insert_label($fb, $xs, 0, $xs+$xr, 2, 'bottom' )  
   if ($self->{type} & EDGE_LABEL_CELL);

  }

sub _draw_ver
  {
  # draw a VER edge piece
  my ($self, $fb) = @_;

  my $style = $self->_edge_style();

  my $h = $self->{h};
  # '|' => '|||||', '{}' => '{}{}{}'
  my $line = $style->[1] x (1 + $h / length($style->[1]));
  $line = substr($line, 0, $h) if length($line) > $h;

  my $flags = $self->{type} & EDGE_FLAG_MASK;
  # XXX TODO: handle here start points
  # we get away with not handling them because in VER edges
  # starting points are currently invisible.

  my $as = $self->_arrow_style();
  if ($as ne 'none')
    {
    my $ashape = $self->_arrow_shape();
    substr($line,0,1) = $self->_arrow($as,ARROW_UP, $ashape)
      if (($flags & EDGE_END_N) != 0);
    substr($line,-1,1) = $self->_arrow($as,ARROW_DOWN, $ashape)
      if (($flags & EDGE_END_S) != 0);
    }
  $self->_printfb_ver ($fb, 2, 0, $line);

  $self->_insert_label($fb, 4, 1, 4, 2, 'middle')
    if ($self->{type} & EDGE_LABEL_CELL);

  }

sub _draw_cross
  {
  # draw a CROSS sections, or a joint (which is a 3/4 cross)
  my ($self, $fb) = @_;
  
  # vertical piece
  my $style = $self->_edge_style( $self->{style_ver} );

  my $invisible = 0;
  my $line;
  my $flags = $self->{type} & EDGE_FLAG_MASK;
  my $type = $self->{type} & EDGE_TYPE_MASK;
  my $as = $self->_arrow_style();
  my $y = $self->{h} - 2;

  print STDERR "# drawing cross at $self->{x},$self->{y} with flags $flags\n" if $self->{debug};

  if ($self->{style_ver} ne 'invisible')
    {
    my $h = $self->{h};
    # '|' => '|||||', '{}' => '{}{}{}'
    $line = $style->[1] x (2 + $h / length($style->[1])); 

    $line = substr($line, 0, $h) if length($line) > $h;

    if ($as ne 'none')
      {
      my $ashape = $self->_arrow_shape();
      substr($line,0,1) = $self->_arrow($as,ARROW_UP, $ashape) 
        if (($flags & EDGE_END_N) != 0);
      substr($line,-1,1) = $self->_arrow($as,ARROW_DOWN, $ashape)
        if (($flags & EDGE_END_S) != 0);
      }

    # create joints
    substr($line,0,$y) = ' ' x $y if $type == EDGE_S_E_W;
    substr($line,$y,2) = '  ' if $type == EDGE_N_E_W;

    $self->_printfb_ver ($fb, 2, 0, $line);
    }
  else { $invisible++; }

  # horizontal piece
  $style = $self->_edge_style();
  
  my $ashape; $ashape = $self->_arrow_style() if $as ne 'none';

  if ($self->{style} ne 'invisible')
    {
    my $w = $self->{w};
    # '-' => '-----', '.-' => '.-.-.-'
    my $len = length($style->[0]); 
    $line = $style->[0] x (2 + $w / $len); 
  
    # '.-.-.-' => '-.-.-' if $x % $ofs == 1 (e.g. on odd positions)
    my $ofs = $self->{rx} % $len;
    substr($line,0,$ofs) = '' if $ofs != 0;

    $line = substr($line, 0, $w) if length($line) > $w;
  
    my $x = 0;
    if (($flags & EDGE_START_W) != 0)
      {
      $x++; chop($line);		# ' ---'
      }
    if (($flags & EDGE_START_E) != 0)
      {
      chop($line);			# '--- '
      }
    if (($flags & EDGE_END_E) != 0)
      {
      # '--> '
      chop($line);
      substr($line,-1,1) = $self->_arrow($as, ARROW_RIGHT, $ashape)
       if $as ne 'none';
      }
    if (($flags & EDGE_END_W) != 0)
      {
      # ' <--'
      substr($line,0,1) = ' ' if $as eq 'none';
      substr($line,0,2) = ' ' . $self->_arrow($as, ARROW_LEFT, $ashape)
       if $as ne 'none';
      }

    substr($line,0,2) = '  ' if $type == EDGE_E_N_S;
    substr($line,2,$self->{w}-2) = ' ' x ($self->{w}-2) if $type == EDGE_W_N_S;

    $self->_printfb_line ($fb, $x, $y, $line);
    }
  else { $invisible++; }

  if (!$invisible)
    {
    # draw the crossing character only if both lines are visible
    my $cross = $style->[2];
    my $s = $self->{style} . $self->{style_ver};
    $cross = ($self->_cross_style($s,$type) || $cross); # if $self->{style_ver} ne $self->{style};

    $self->_printfb ($fb, 2, $y, $cross);
    }

  # done
  }

sub _draw_corner
  {
  # draw a corner (N_E, S_E etc)
  my ($self, $fb) = @_;

  my $type = $self->{type} & EDGE_TYPE_MASK;
  my $flags = $self->{type} & EDGE_FLAG_MASK;

  ############
  #   ........
  # 0 :      :
  # 1 :      :    label would appear here
  # 2 :  +---:    (w-3) = 3 chars wide
  # 3 :  |   :    always 1 char high
  #   .......:
  #    012345 

  # draw the vertical piece
 
  # get the style
  my $style = $self->_edge_style();
 
  my $h = 1; my $y = $self->{h} -1; 
  if ($type == EDGE_N_E || $type == EDGE_N_W)
    {
    $h = $self->{h} - 2; $y = 0; 
    }
  # '|' => '|||||', '{}' => '{}{}{}'
  my $line = $style->[1] x (1 + $h / length($style->[1])); 
  $line = substr($line, 0, $h) if length($line) > $h;

  my $as = $self->_arrow_style();
  my $ashape;
  if ($as ne 'none')
    {
    $ashape = $self->_arrow_shape();
    substr($line,0,1) = $self->_arrow($as, ARROW_UP, $ashape)
      if (($flags & EDGE_END_N) != 0);
    substr($line,-1,1) = $self->_arrow($as, ARROW_DOWN, $ashape)
      if (($flags & EDGE_END_S) != 0);
    }
  $self->_printfb_ver ($fb, 2, $y, $line);

  # horizontal piece
  my $w = $self->{w} - 3; $y = $self->{h} - 2; my $x = 3;
  if ($type == EDGE_N_W || $type == EDGE_S_W)
    {
    $w = 2; $x = 0; 
    }

  # '-' => '-----', '.-' => '.-.-.-'
  my $len = length($style->[0]); 
  $line = $style->[0] x (2 + $w / $len); 
  
  # '.-.-.-' => '-.-.-' if $x % $ofs == 1 (e.g. on odd positions)
  my $ofs = ($x + $self->{rx}) % $len;
  substr($line,0,$ofs) = '' if $ofs != 0;

  $line = substr($line, 0, $w) if length($line) > $w;
  
  substr($line,-1,1) = ' ' if ($flags & EDGE_START_E) != 0;
  substr($line,0,1) = ' '  if ($flags & EDGE_START_W) != 0;

  if (($flags & EDGE_END_E) != 0)
    {
    substr($line,-1,1) = ' ' if $as eq 'none';
    substr($line,-2,2) = $self->_arrow($as, ARROW_RIGHT, $ashape) . ' ' if $as ne 'none';
    }
  if (($flags & EDGE_END_W) != 0)
    {
    substr($line,0,1) = ' ' if $as eq 'none';
    substr($line,0,2) = ' ' . $self->_arrow($as, ARROW_LEFT, $ashape) if $as ne 'none';
    }

  $self->_printfb_line ($fb, $x, $y, $line);

  my $idx = 3; 		# corner (SE, SW, NE, NW)
  $idx = 4 if $type == EDGE_S_W;
  $idx = 5 if $type == EDGE_N_E;
  $idx = 6 if $type == EDGE_N_W;

  # insert the corner character
  $self->_printfb ($fb, 2, $y, $style->[$idx]);
  }

sub _draw_loop_hor
  {
  my ($self, $fb) = @_;

  my $type = $self->{type} & EDGE_TYPE_MASK;
  my $flags = $self->{type} & EDGE_FLAG_MASK;

  ############
  #   ..........
  # 0 :        :
  # 1 :        :    label would appear here
  # 2 :  +--+  :    (w-6) = 2 chars wide
  # 3 :  |  v  :    1 char high
  #   .........:
  #    01234567 

  ############
  #   ..........
  # 0 :  |  ^  :    ver is h-2 chars high	
  # 1 :  |  |  :    label would appear here
  # 2 :  +--+  :    (w-6) = 2 chars wide
  # 3 :        :
  #   .........:
  #    01234567 

  # draw the vertical pieces
 
  # get the style
  my $style = $self->_edge_style();
 
  my $h = 1; my $y = $self->{h} - 1; 
  if ($type == EDGE_S_W_N)
    {
    $h = $self->{h} - 2; $y = 0; 
    }
  # '|' => '|||||', '{}' => '{}{}{}'
  my $line = $style->[1] x (1 + $h / length($style->[1])); 
  $line = substr($line, 0, $h) if length($line) > $h;
  
  my $as = $self->_arrow_style();
  my $ashape; $ashape = $self->_arrow_shape() if $as ne 'none';

  if ($self->{edge}->{bidirectional} && $as ne 'none')
    {
    substr($line,0,1)  = $self->_arrow($as, ARROW_UP, $ashape) if (($flags & EDGE_END_N) != 0);
    substr($line,-1,1) = $self->_arrow($as, ARROW_DOWN, $ashape) if (($flags & EDGE_END_S) != 0);
    }
  $self->_printfb_ver ($fb, $self->{w}-3, $y, $line);

  if ($as ne 'none')
    {
    substr($line,0,1)  = $self->_arrow($as, ARROW_UP, $ashape) if (($flags & EDGE_END_N) != 0);
    substr($line,-1,1) = $self->_arrow($as, ARROW_DOWN, $ashape) if (($flags & EDGE_END_S) != 0);
    }
  $self->_printfb_ver ($fb, 2, $y, $line);

  # horizontal piece
  my $w = $self->{w} - 6; $y = $self->{h} - 2; my $x = 3;

  # '-' => '-----', '.-' => '.-.-.-'
  my $len = length($style->[0]); 
  $line = $style->[0] x (2 + $w / $len); 
  
  # '.-.-.-' => '-.-.-' if $x % $ofs == 1 (e.g. on odd positions)
  my $ofs = ($x + $self->{rx}) % $len;
  substr($line,0,$ofs) = '' if $ofs != 0;

  $line = substr($line, 0, $w) if length($line) > $w;
  
  $self->_printfb_line ($fb, $x, $y, $line);
  
  my $corner_idx = 3; $corner_idx = 5 if $type == EDGE_S_W_N;

  # insert the corner characters
  $self->_printfb ($fb, 2, $y, $style->[$corner_idx]);
  $self->_printfb ($fb, $self->{w}-3, $y, $style->[$corner_idx+1]);

  my $align = 'bottom'; $align = 'top' if $type == EDGE_S_W_N;
  $self->_insert_label($fb, 4, 0, 4, 2, $align)
  if ($self->{type} & EDGE_LABEL_CELL);

  # done
  }

sub _draw_loop_ver
  {
  my ($self, $fb) = @_;

  my $type = $self->{type} & EDGE_TYPE_MASK;
  my $flags = $self->{type} & EDGE_FLAG_MASK;

  ############
  #   ........
  # 0 :      :  label would appear here
  # 1 :  +-- :
  # 2 :  |   :
  # 3 :  +-> :
  #   .......:
  #    012345 

  #   ........
  # 0 :      :  label would appear here
  # 1 : --+  :
  # 2 :   |  :
  # 3 : <-+  :
  #   .......:
  #    012345 

  ###########################################################################
  # draw the vertical piece
 
  # get the style
  my $style = $self->_edge_style();
 
  my $h = 1; my $y = $self->{h} - 3; 
  # '|' => '|||||', '{}' => '{}{}{}'
  my $line = $style->[1] x (1 + $h / length($style->[1])); 
  $line = substr($line, 0, $h) if length($line) > $h;

  my $x = 2; $x = $self->{w}-3 if ($type == EDGE_E_S_W);
  $self->_printfb_ver ($fb, $x, $y, $line);

  ###########################################################################
  # horizontal pieces

  my $w = $self->{w} - 3; $y = $self->{h} - 4;
  $x = 2; $x = 1 if ($type == EDGE_E_S_W);

  # '-' => '-----', '.-' => '.-.-.-'
  my $len = length($style->[0]); 
  $line = $style->[0] x (2 + $w / $len); 
  
  # '.-.-.-' => '-.-.-' if $x % $ofs == 1 (e.g. on odd positions)
  my $ofs = ($x + $self->{rx}) % $len;
  substr($line,0,$ofs) = '' if $ofs != 0;

  $line = substr($line, 0, $w) if length($line) > $w;

  my $as = $self->_arrow_style();
  my $ashape; $ashape = $self->_arrow_shape() if $as ne 'none';
 
  if ($self->{edge}->{bidirectional} && $as ne 'none')
    {
    substr($line,0,1)  = $self->_arrow($as, ARROW_LEFT, $ashape) if (($flags & EDGE_END_W) != 0);
    substr($line,-1,1) = $self->_arrow($as, ARROW_RIGHT, $ashape) if (($flags & EDGE_END_E) != 0);
    }

  $self->_printfb_line ($fb, $x, $y, $line);

  if ($as ne 'none')
    {
    substr($line,0,1)  = $self->_arrow($as, ARROW_LEFT, $ashape) if (($flags & EDGE_END_W) != 0);
    substr($line,-1,1) = $self->_arrow($as, ARROW_RIGHT, $ashape) if (($flags & EDGE_END_E) != 0);
    }
  
  $self->_printfb_line ($fb, $x, $self->{h} - 2, $line);

  $x = 2; $x = $self->{w}-3 if ($type == EDGE_E_S_W);

  my $corner_idx = 3; $corner_idx = 4 if $type == EDGE_E_S_W;

  # insert the corner characters
  $self->_printfb ($fb, $x, $y, $style->[$corner_idx]);
  $self->_printfb ($fb, $x, $self->{h}-2, $style->[$corner_idx+2]);

  $x = 4; $x = 3 if ($type == EDGE_E_S_W);
  $self->_insert_label($fb, $x, 0, $x, 4, 'bottom')
    if ($self->{type} & EDGE_LABEL_CELL);

  # done
  }

# which method to call for which edge type
my $draw_dispatch =
  {
  EDGE_HOR() => '_draw_hor',
  EDGE_VER() => '_draw_ver',

  EDGE_S_E() => '_draw_corner', 
  EDGE_S_W() => '_draw_corner',
  EDGE_N_E() => '_draw_corner',
  EDGE_N_W() => '_draw_corner',

  EDGE_CROSS() => '_draw_cross',
  EDGE_W_N_S() => '_draw_cross',
  EDGE_E_N_S() => '_draw_cross',
  EDGE_N_E_W() => '_draw_cross',
  EDGE_S_E_W() => '_draw_cross',

  EDGE_N_W_S() => '_draw_loop_hor',
  EDGE_S_W_N() => '_draw_loop_hor',

  EDGE_E_S_W() => '_draw_loop_ver',
  EDGE_W_S_E() => '_draw_loop_ver',
  };

sub _draw_label
  {
  # This routine is cunningly named _draw_label, because it actually
  # draws the edge line(s). The label text will be drawn by the individual
  # routines called below.
  my ($self, $fb, $x, $y) = @_;

  my $type = $self->{type} & EDGE_TYPE_MASK;

  # for cross sections, we maybe need to draw one of the parts:
  return if $self->attribute('style') eq 'invisible' && $type ne EDGE_CROSS;

  my $m = $draw_dispatch->{$type};

  $self->_croak("Unknown edge type $type") unless defined $m;

  # store the coordinates of our upper-left corner (for seamless rendering)
  $self->{rx} = $x || 0; $self->{ry} = $y || 0;
  $self->$m($fb);
  delete $self->{rx}; delete $self->{ry};	# no longer needed
  }

#############################################################################
#############################################################################

package Graph::Easy::Node;

use strict;

sub _framebuffer
  {
  # generate an actual framebuffer consisting of spaces
  my ($self, $w, $h) = @_;

  print STDERR "# trying to generate framebuffer of undefined width for $self->{name}\n",
               join (": ", caller(),"\n") if !defined $w;

  my @fb;

  my $line = ' ' x $w;
  for my $y (1..$h)
    {
    push @fb, $line;
    }
  \@fb;
  }

sub _printfb_aligned
  {
  my ($self,$fb, $x1,$y1, $w,$h, $lines, $aligns, $align_ver) = @_;

  $align_ver = 'middle' unless $align_ver;

  # $align_ver eq 'middle':
  my $y = $y1 + ($h / 2) - (scalar @$lines / 2);
  if ($align_ver eq 'top')
    {
    $y = $y1; 
    $y1 = 0;
    }
  if ($align_ver eq 'bottom')
    {
    $y = $h - scalar @$lines; $y1 = 0; 
    }

  my $xc = ($w / 2);

  my $i = 0;
  while ($i < @$lines)
    {
    # get the line and her alignment
    my ($l,$al) = ($lines->[$i],$aligns->[$i]);

    my $x = 0;			# left is default

    $x = $xc - length($l) / 2 if $al eq 'c';
    $x = $w - length($l) if $al eq 'r';

    # now print the line (inlined print_fb_line for speed)
    substr ($fb->[int($y+$i+$y1)], int($x+$x1), length($l)) = $l;

    $i++;
    }
  }

sub _printfb_line
  {
  # Print one textline into a framebuffer
  # Caller MUST ensure proper size of FB, for speed reasons,
  # we do not check whether text fits!
  my ($self, $fb, $x, $y, $l) = @_;

  # [0] = '0123456789...'

  substr ($fb->[$y], $x, length($l)) = $l;
  }

sub _printfb
  {
  # Print (potential a multiline) text into a framebuffer
  # Caller MUST ensure proper size of FB, for speed reasons,
  # we do not check whether the text fits!
  my ($self, $fb, $x, $y, @lines) = @_;

  # [0] = '0123456789...'
  # [1] = '0123456789...' etc

  for my $l (@lines)
    {
#    # XXX DEBUG:
#    if ( $x + length($l) > length($fb->[$y]))
#      {
#      require Carp;
#      Carp::confess("substr outside framebuffer");
#      }

    substr ($fb->[$y], $x, length($l)) = $l; $y++;
    }
  }

sub _printfb_ver
  {
  # Print a string vertical into a framebuffer.
  # Caller MUST ensure proper size of FB, for speed reasons,
  # we do not check whether text fits!
  my ($self, $fb, $x, $y, $line) = @_;

  # this more than twice as fast as:
  #  "@pieces = split//,$line; _printfb(...)"

  my $y1 = $y + length($line);
  substr ($fb->[$y1], $x, 1) = chop($line) while ($y1-- > $y);
  }

 # for ASCII and box drawing:

 # the array contains for each style:
 # upper left edge
 # upper right edge
 # lower right edge
 # lower left edge
 # hor style (top edge)
 # hor style (bottom side)
 # ver style (right side) (multiple characters possible)
 # ver style (left side) (multiple characters possible)
 # T crossing (see drawing below)
 # T to right
 # T to left
 # T to top
 # T shape (to bottom)
 
 #
 # +-----4-----4------+
 # |     |     |      |
 # |     |     |      |
 # |     |     |      |
 # 1-----0-----3------2		1 = T to right, 2 = T to left, 3 T to top
 # |     |			0 = cross, 4 = T shape
 # |     |
 # |     |
 # +-----+

my $border_styles = 
  [
  {
  solid =>		[ '+', '+', '+', '+', '-',   '-',   [ '|'      ], [ '|'     ], '+', '+', '+', '+', '+' ],
  dotted =>		[ '.', '.', ':', ':', '.',   '.',   [ ':'      ], [ ':'     ], '.', '.', '.', '.', '.' ],
  dashed =>		[ '+', '+', '+', '+', '- ',  '- ',  [ "'"      ], [ "'"     ], '+', '+', '+', '+', '+' ],
  'dot-dash' =>		[ '+', '+', '+', '+', '.-',  '.-',  [ '!'      ], [ '!'     ], '+', '+', '+', '+', '+' ],
  'dot-dot-dash' =>	[ '+', '+', '+', '+', '..-', '..-', [ '|', ':' ], [ '|',':' ], '+', '+', '+', '+', '+' ],
  bold =>		[ '#', '#', '#', '#', '#',   '#',   [ '#'      ], [ '#'     ], '#', '#', '#', '#', '#' ],
  'bold-dash' =>	[ '#', '#', '#', '#', '# ',  '# ',  ['#',' '   ], [ '#',' ' ], '#', '#', '#', '#', '#' ],
  double =>		[ '#', '#', '#', '#', '=',   '=',   [ 'H'      ], [ 'H'     ], '#', '#', '#', '#', '#' ],
  'double-dash' =>	[ '#', '#', '#', '#', '= ',  '= ',  [ '"'      ], [ '"'     ], '#', '#', '#', '#', '#' ],
  wave =>		[ '+', '+', '+', '+', '~',   '~',   [ '{', '}' ], [ '{','}' ], '+', '+', '+', '+', '+' ],
  broad =>		[ '#', '#', '#', '#', '#',   '#',   [ '#'      ], [ '#'     ], '#', '#', '#', '#', '#' ],
  wide =>		[ '#', '#', '#', '#', '#',   '#',   [ '#'      ], [ '#'     ], '#', '#', '#', '#', '#' ],
  none =>		[ ' ', ' ', ' ', ' ', ' ',   ' ',   [ ' '      ], [ ' '     ], ' ', ' ', ' ', ' ', ' ' ],
  },
  {
  solid =>		[ '┌', '┐', '┘', '└', '─', '─',     [ '│' ], [ '│' ], '┼', '├', '┤', '┴', '┬' ],
  double =>		[ '╔', '╗', '╝', '╚', '═', '═',     [ '║' ], [ '║' ], '┼', '├', '┤', '┴', '┬' ],
  dotted =>		[ '┌', '┐', '┘', '└', '⋯', '⋯', [ '⋮' ], [ '⋮' ], '┼', '├', '┤', '┴', '┬' ],
  dashed =>		[ '┌', '┐', '┘', '└', '−', '−', [ '╎' ], [ '╎' ], '┼', '├', '┤', '┴', '┬' ],
  'dot-dash' =>		[ '┌', '┐', '┘', '└', '·'.'-', '·'.'-', ['!'], ['!'], '┼', '├', '┤', '┴', '┬' ],
  'dot-dot-dash' =>	[ '┌', '┐', '┘', '└', ('·' x 2) .'-', ('·' x 2) .'-', [ '│', ':' ], [ '│', ':' ], '┼', '├', '┤', '┴', '┬' ],
  bold =>		[ '┏', '┓', '┛', '┗', '━', '━', [ '┃' ], [ '┃' ], '┼', '├', '┤', '┴', '┬' ],
  'bold-dash' =>	[ '┏', '┓', '┛', '┗', '━'.' ', '━'.' ', [ '╻' ], [ '╻' ], '┼', '├', '┤', '┴', '┬' ],
  'double-dash' =>	[ '╔', '╗', '╝', '╚', '═'.' ', '═'.' ', [ '∥' ], [ '∥' ], '┼', '├', '┤', '┴', '┬' ],
  wave =>		[ '┌', '┐', '┘', '└', '∼',  '∼', [ '≀' ], [ '≀' ], '┼', '├', '┤', '┴', '┬' ],
  broad =>		[ '▛', '▜', '▟', '▙', '▀', '▄', [ '▌' ], [ '▐' ], '▄', '├', '┤', '┴', '┬' ],
  wide =>		[ '█', '█', '█', '█', '█', '█', [ '█' ], [ '█' ], '█', '█', '█', '█', '█' ],
  none =>		[ ' ', ' ', ' ', ' ', ' ', ' ',  [ ' ' ], [ ' ' ], ' ', ' ', ' ', ' ', ' ', ],
  },
  ];

 # for boxart and rounded corners on node-borders:
 # upper left edge
 # upper right edge
 # lower right edge
 # lower left edge

my $rounded_edges = [ '╭', '╮', '╯', '╰', ]; 

 # for ASCII/boxart drawing slopes/slants
 #             lower-left to upper right (repeated twice)
 #                   lower-right to upper left (repeated twice)
my $slants = [
  # ascii
  {                    
  solid	 	 => [ '/'  , '\\'   ],
  dotted	 => [ '.' , '.'     ],
  dashed	 => [ '/ ', '\\ '   ],
  'dot-dash'	 => [ './', '.\\'   ],
  'dot-dot-dash' => [ '../', '..\\' ],
  bold	 	 => [ '#' , '#'     ],
  'bold-dash' 	 => [ '# ' , '# '   ],
  'double' 	 => [ '/' , '\\'    ],
  'double-dash'	 => [ '/ ' , '\\ '  ],
  wave	 	 => [ '/ ' , '\\ '  ],
  broad	 	 => [ '#' , '#'     ],
  wide	 	 => [ '#' , '#'     ],
  },
  # boxart
  {                     
  solid	 	 => [ '╱'  , '╲'   ],
  dotted	 => [ '⋰' , '⋱'    ],
  dashed	 => [ '╱ ', '╲ '   ],
  'dot-dash'	 => [ '.╱', '.╲'   ],
  'dot-dot-dash' => [ '⋰╱', '⋱╲' ],
  bold	 	 => [ '#' , '#'    ],
  'bold-dash' 	 => [ '# ' , '# '  ],
  'double' 	 => [ '╱' , '╲'    ],
  'double-dash'	 => [ '╱ ' , '╲ '  ],
  wave	 	 => [ '╱ ' , '╲ '  ],
  broad	 	 => [ '#' , '#'    ],
  wide	 	 => [ '#' , '#'    ],
  },
  ];

 # ASCII and box art: the different point shapes and styles
my $point_shapes = 
  [ {
    filled => 
      {
      'star'		=> '*',
      'square'		=> '#',
      'dot'		=> '.',
      'circle'		=> 'o',  # unfortunately, there is no filled o in ASCII
      'cross'		=> '+',
      'diamond'		=> '<>',
      'x'		=> 'X',
      },
    closed => 
      {
      'star'		=> '*',
      'square'		=> '#',
      'dot'		=> '.',
      'circle'		=> 'o',
      'cross'		=> '+',
      'diamond'		=> '<>',
      'x'		=> 'X',
      },
    },
    {
    filled =>
      {
      'star'		=> '★',
      'square'		=> '■',
      'dot'		=> '·',
      'circle'		=> '●',
      'cross'		=> '+',
      'diamond'		=> '◆',
      'x'		=> '╳',
      },
    closed => 
      {
      'star'		=> '☆',
      'square'		=> '□',
      'dot'		=> '·',
      'circle'		=> '○',
      'cross'		=> '+',
      'diamond'		=> '◇',
      'x'		=> '╳',
      },
    }
  ];  

sub _point_style
  {
  my ($self, $shape, $style) = @_;

  return '' if $shape eq 'invisible';

  if ($style =~ /^(star|square|dot|circle|cross|diamond)\z/)
    {
    # support the old "pointstyle: diamond" notion:
    $shape = $style; $style = 'filled';
    }

  $style = 'filled' unless defined $style;
  my $g = $self->{graph}->{_ascii_style} || 0;
  $point_shapes->[$g]->{$style}->{$shape};
  }

sub _border_style
  {
  my ($self, $style, $type) = @_;

  # make a copy so that we can modify it
  my $g = $self->{graph}->{_ascii_style} || 0;
  my $s = [ @{ $border_styles->[ $g ]->{$style} } ];

  die ("Unknown $type border style '$style'") if @$s == 0;

  my $shape = 'rect';
  $shape = $self->attribute('shape') unless $self->isa_cell();
  return $s unless $shape eq 'rounded';

  # if shape: rounded, overlay the rounded edge pieces
  splice (@$s, 0, 4, @$rounded_edges)
    if $style =~ /^(solid|dotted|dashed|dot-dash|dot-dot-dash)\z/;

  # '####' => ' ### '
  splice (@$s, 0, 4, (' ', ' ', ' ', ' '))
    if $g == 0 || $style =~ /^(bold|wide|broad|double|double-dash|bold-dash)\z/;

  $s;
  }

#############################################################################
# different arrow styles and shapes in ASCII and boxart

my $arrow_form =
  {
  normal => 0,
  sleek => 1,			# slightly squashed
  };

my $arrow_shapes =
  {
  triangle => 0,
  diamond => 1,
  box => 2,
  dot => 3,
  inv => 4,			# an inverted triangle
  line => 5,
  cross => 6,
  x => 7,
  };

# todo: ≪ ≫ 

my $arrow_styles = 
  [
    [
    # triangle
      {
      open   => [ '>', '<', '^', 'v' ],
      closed => [ '>', '<', '^', 'v' ],
      filled => [ '>', '<', '^', 'v' ],
      },
      {
      open   => [ '>', '<', '∧', '∨' ],
      closed => [ '▷', '◁', '△', '▽' ],
      filled => [ '▶', '◀', '▲', '▼' ],
      }
    ], [
    # diamond
      {
      open   => [ '>', '<', '^', 'v' ],
      closed => [ '>', '<', '^', 'v' ],
      filled => [ '>', '<', '^', 'v' ],
      },
      {
      open   => [ '>', '<', '∧', '∨' ],
      closed => [ '◇', '◇', '◇', '◇' ],
      filled => [ '◆', '◆', '◆', '◆' ],
      }
    ], [
    # box
      {
      open   => [ ']', '[', '°', 'u' ],
      closed => [ 'D', 'D', 'D', 'D' ],
      filled => [ '#', '#', '#', '#' ],
      },
      {
      open   => [ '⊐', '⊐', '⊓', '⊔' ],
      closed => [ '◻', '◻', '◻', '◻' ],
      filled => [ '◼', '◼', '◼', '◼' ],
      }
    ], [
    # dot
      {
      open   => [ ')', '(', '^', 'u' ],
      closed => [ 'o', 'o', 'o', 'o' ],
      filled => [ '*', '*', '*', '*' ],
      },
      {
      open   => [ ')', '(', '◠', '◡' ],
      closed => [ '○', '○', '○', '○' ],
      filled => [ '●', '●', '●', '●' ],
      }
    ], [
    # inv
      {
      open   => [ '<', '>', 'v', '^' ],
      closed => [ '<', '>', 'v', '^' ],
      filled => [ '<', '>', 'v', '^' ],
      },
      {
      open   => [ '<', '>', '∨', '∧' ],
      closed => [ '◁', '▷', '▽', '△' ],
      filled => [ '◀', '▶', '▼', '▲' ],
      }
    ], [
    # line
      {
      open   => [ '|', '|', '_', '-' ],
      closed => [ '|', '|', '_', '-' ],
      filled => [ '|', '|', '_', '-' ],
      },
      {
      open   => [ '⎥', '⎢', '_', '¯' ],
      closed => [ '⎥', '⎢', '_', '¯' ],
      filled => [ '⎥', '⎢', '_', '¯' ],
      }
    ], [
    # cross
      {
      open   => [ '+', '+', '+', '+' ],
      closed => [ '+', '+', '+', '+' ],
      filled => [ '+', '+', '+', '+' ],
      },
      {
      open   => [ '┼', '┼', '┼', '┼' ],
      closed => [ '┼', '┼', '┼', '┼' ],
      filled => [ '┼', '┼', '┼', '┼' ],
      }
    ], [
    # x
      {
      open   => [ 'x', 'x', 'x', 'x' ],
      closed => [ 'x', 'x', 'x', 'x' ],
      filled => [ 'x', 'x', 'x', 'x' ],
      },
      {
      open   => [ 'x', 'x', 'x', 'x' ],
      closed => [ 'x', 'x', 'x', 'x' ],
      filled => [ '⧓', '⧓', 'x', 'x' ],
      }
    ]
  ];

sub _arrow
  {
  # return an arror, depending on style and direction
  my ($self, $style, $dir, $shape) = @_;

  $shape = '' unless defined $shape;
  $shape = $arrow_shapes->{$shape} || 0;

  my $g = $self->{graph}->{_ascii_style} || 0;
  $arrow_styles->[$shape]->[$g]->{$style}->[$dir];
  }

# To convert an HTML arrow to Unicode:
my $arrow_dir = {
  '&gt;' => 0,
  '&lt;' => 1,
  '^' => 2,
  'v' => 3,
  };

sub _unicode_arrow
  {
  # return an arror in unicode, depending on style and direction
  my ($self, $shape, $style, $arrow_text) = @_;

  $shape = '' unless defined $shape;
  $shape = $arrow_shapes->{$shape} || 0;

  my $dir = $arrow_dir->{$arrow_text} || 0;

  $arrow_styles->[$shape]->[1]->{$style}->[$dir];
  }

#############################################################################

#
# +---4---4---4---+
# |   |   |   |   |
# |   |   |   |   |
# |   |   |   |   |
# 1---0---3---0---2	1 = T to right, 2 = T to left, 3 T to top
# |   |       |   |	0 = cross, 4 = T shape
# |   |       |   |
# |   |       |   |
# +---+       +---+

sub _draw_border
  {
  # draws a border into the framebuffer
  my ($self, $fb, $do_right, $do_bottom, $do_left, $do_top, $x, $y) = @_;

  return if $do_right.$do_left.$do_bottom.$do_top eq 'nonenonenonenone';

  my $g = $self->{graph};

  my $w = $self->{w};
  if ($do_top ne 'none')
    {
    my $style = $self->_border_style($do_top, 'top');

    # top-left corner piece is only there if we have a left border
    my $tl = $style->[0]; $tl = '' if $do_left eq 'none';

    # generate the top border
    my $top = $style->[4] x (($self->{w}) / length($style->[4]) + 1);

    my $len = length($style->[4]); 

    # for seamless rendering
    if (defined $x)
      {
      my $ofs = $x % $len;
      substr($top,0,$ofs) = '' if $ofs != 0;
      }

    # insert left upper corner (if it is there)
    substr($top,0,1) = $tl if $tl ne '';

    $top = substr($top,0,$w) if length($top) > $w;
    
    # top-right corner piece is only there if we have a right border
    substr($top,-1,1) = $style->[1] if $do_right ne 'none';

    # if the border must be collapsed, modify top-right edge piece:
    if ($self->{border_collapse_right})
      {
      # place "4" (see drawing above)
      substr($top,-1,1) = $style->[10];
      }

    # insert top row into FB
    $self->_printfb( $fb, 0,0, $top);
    }

  if ($do_bottom ne 'none')
    {
    my $style = $self->_border_style($do_bottom, 'bottom');

    # bottom-left corner piece is only there if we have a left border
    my $bl = $style->[3]; $bl = '' if $do_left eq 'none';

    # the bottom row '+--------+' etc
    my $bottom = $style->[5] x (($self->{w}) / length($style->[5]) + 1);

    my $len = length($style->[5]);
 
    # for seamless rendering
    if (defined $x)
      {
      my $ofs = $x % $len;
      substr($bottom,0,$ofs) = '' if $ofs != 0;
      }

    # insert left bottom corner (if it is there)
    substr($bottom,0,1) = $bl if $bl ne '';

    $bottom = substr($bottom,0,$w) if length($bottom) > $w;

    # bottom-right corner piece is only there if we have a right border
    substr($bottom,-1,1) = $style->[2] if $do_right ne 'none';

    # if the border must be collapsed, modify bottom-right edge piece:
    if ($self->{border_collapse_right} || $self->{border_collapse_bottom})
      {
      if ($self->{rightbelow_count} > 0)
        {
        # place a cross or T piece (see drawing above)
        my $piece = 8;	# cross
        # inverted T
        $piece = 11 if $self->{rightbelow_count} < 2 && !$self->{have_below};
        $piece = 10 if $self->{rightbelow_count} < 2 && !$self->{have_right};
        substr($bottom,-1,1) = $style->[$piece];
        }
      }

    # insert bottom row into FB
    $self->_printfb( $fb, 0,$self->{h}-1, $bottom);
    }

  return if $do_right.$do_left eq 'nonenone';	# both none => done

  my $style = $self->_border_style($do_left, 'left');
  my $left = $style->[6];
  my $lc = scalar @{ $style->[6] } - 1;		# count of characters

  $style = $self->_border_style($do_right, 'right');
  my $right = $style->[7];
  my $rc = scalar @{ $style->[7] } - 1;		# count of characters

  my (@left, @right);
  my $l = 0; my $r = 0;				# start with first character
  my $s = 1; $s = 0 if $do_top eq 'none';

  my $h = $self->{h} - 2;
  $h ++ if defined $x && $do_bottom eq 'none';	# for seamless rendering
  for ($s..$h)
    {
    push @left, $left->[$l]; $l ++; $l = 0 if $l > $lc;
    push @right, $right->[$r]; $r ++; $r = 0 if $r > $rc;
    }
  # insert left/right columns into FB
  $self->_printfb( $fb, 0, $s, @left) unless $do_left eq 'none';
  $self->_printfb( $fb, $w-1, $s, @right) unless $do_right eq 'none';

  $self;
  }
 
sub _draw_label
  {
  # Draw the node label into the framebuffer
  my ($self, $fb, $x, $y, $shape) = @_;

  if ($shape eq 'point')
    {
    # point-shaped nodes do not show their label in ASCII
    my $style = $self->attribute('pointstyle');
    my $shape = $self->attribute('pointshape');
    my $l = $self->_point_style($shape,$style);

    $self->_printfb_line ($fb, 2, $self->{h} - 2, $l) if $l;
    return;
    }

  #        +----
  #        | Label  
  # 2,1: ----^

  my $w = $self->{w} - 4; my $xs = 2;
  my $h = $self->{h} - 2; my $ys = 0.5;
  my $border = $self->attribute('borderstyle');
  if ($border eq 'none')
    {
    $w += 2; $h += 2;
    $xs = 1; $ys = 0;
    }

  my $align = $self->attribute('align');
  $self->_printfb_aligned ($fb, $xs, $ys, $w, $h, $self->_aligned_label($align));
  }

sub as_ascii
  {
  # renders a node or edge like:
  # +--------+    ..........    ""
  # | A node | or : A node : or " --> "
  # +--------+    ..........    "" 
  my ($self, $x,$y) = @_;

  my $shape = 'rect';
  $shape = $self->attribute('shape') unless $self->isa_cell();

  if ($shape eq 'edge')
    {
    my $edge = Graph::Easy::Edge->new();
    my $cell = Graph::Easy::Edge::Cell->new( edge => $edge, x => $x, y => $y );
    $cell->{w} = $self->{w};
    $cell->{h} = $self->{h};
    $cell->{att}->{label} = $self->label();
    $cell->{type} = 
     Graph::Easy::Edge::Cell->EDGE_HOR +
     Graph::Easy::Edge::Cell->EDGE_LABEL_CELL;
    return $cell->as_ascii();
    }

  # invisible nodes, or very small ones
  return '' if $shape eq 'invisible' || $self->{w} == 0 || $self->{h} == 0;

  my $fb = $self->_framebuffer($self->{w}, $self->{h});

  # point-shaped nodes do not have a border
  if ($shape ne 'point')
    {
    #########################################################################
    # draw our border into the framebuffer

    my $cache = $self->{cache};
    my $b_top = $cache->{top_border} || 'none';
    my $b_left = $cache->{left_border} || 'none';
    my $b_right = $cache->{right_border} || 'none';
    my $b_bottom = $cache->{bottom_border} || 'none';

    $self->_draw_border($fb, $b_right, $b_bottom, $b_left, $b_top);
    }

  ###########################################################################
  # "draw" the label into the framebuffer (e.g. the node/edge and the text)

  $self->_draw_label($fb, $x, $y, $shape);
  
  join ("\n", @$fb);
  }

1;
__END__

=head1 NAME

Graph::Easy::As_ascii - Generate ASCII art

=head1 SYNOPSIS

        use Graph::Easy;

	my $graph = Graph::Easy->new();

	$graph->add_edge('Bonn', 'Berlin');

	print $graph->as_ascii();

=head1 DESCRIPTION

C<Graph::Easy::As_ascii> contains the code to render Nodes/Edges as
ASCII art. It is used by Graph::Easy automatically, and there should
be no need to use it directly.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2007 by Tels L<http://bloodgate.com>.

See the LICENSE file for more details.

=cut
#############################################################################
# Output an Graph::Easy object as GraphML text
#
#############################################################################

package Graph::Easy::As_graphml;

$VERSION = '0.03';

#############################################################################
#############################################################################

package Graph::Easy;

use strict;

use Graph::Easy::Attributes;

# map the Graph::Easy attribute types to a GraphML name:
my $attr_type_to_name =
  {
  ATTR_STRING()	=> 'string',
  ATTR_COLOR()	=> 'string',
  ATTR_ANGLE()	=> 'double',
  ATTR_PORT()	=> 'string',
  ATTR_UINT()	=> 'integer',
  ATTR_URL()	=> 'string',

  ATTR_LIST()	=> 'string',
  ATTR_LCTEXT()	=> 'string',
  ATTR_TEXT()	=> 'string',
  };

sub _graphml_attr_keys
  {
  my ($self, $tpl, $tpl_no_default, $class, $att, $ids, $id) = @_;

  my $base_class = $class; $base_class =~ s/\..*//;
  $base_class = 'graph' if $base_class =~ /group/;
  $ids->{$base_class} = {} unless ref $ids->{$base_class};

  my $txt = '';
  for my $name (sort keys %$att)
    {
    my $entry = $self->_attribute_entry($class,$name);
    # get a fresh template
    my $t = $tpl;
    $t = $tpl_no_default unless defined $entry->[ ATTR_DEFAULT_SLOT ];

    # only keep it once
    next if exists $ids->{$base_class}->{$name};

    $t =~ s/##id##/$$id/;

    # node.foo => node, group.bar => graph
    $t =~ s/##class##/$base_class/;
    $t =~ s/##name##/$name/;
    $t =~ s/##type##/$attr_type_to_name->{ $entry->[ ATTR_TYPE_SLOT ] || ATTR_COLOR }/eg;

    # will only be there and thus replaced if we have a default
    if ($t =~ /##default##/)
      {
      my $def = $entry->[ ATTR_DEFAULT_SLOT ];
      # not a simple value?
      $def = $self->default_attribute($name) if ref $def;
      $t =~ s/##default##/$def/;
      }

    # remember name => ID
    $ids->{$base_class}->{$name} = $$id; $$id++;
    # append the definition
    $txt .= $t;
    }
  $txt;
  }

# yED example:

# <data key="d0">
#  <y:ShapeNode>
#    <y:Geometry height="30.0" width="30.0" x="277.0" y="96.0"/>
#    <y:Fill color="#FFCC00" transparent="false"/>
#    <y:BorderStyle color="#000000" type="line" width="1.0"/>
#    <y:NodeLabel alignment="center" autoSizePolicy="content" fontFamily="Dialog" fontSize="12" fontStyle="plain" hasBackgroundColor="false" hasLineColor="false" height="18.701171875" modelName="internal" modelPosition="c" textColor="#000000" visible="true" width="11.0" x="9.5" y="5.6494140625">1</y:NodeLabel>
#    <y:Shape type="ellipse"/>
#   </y:ShapeNode>
# </data>

sub _as_graphml
  {
  my $self = shift;

  my $args = $_[0];
  $args = { name => $_[0] } if ref($args) ne 'HASH' && @_ == 1;
  $args = { @_ } if ref($args) ne 'HASH' && @_ > 1;
  
  $args->{format} = 'graph-easy' unless defined $args->{format};

  if ($args->{format} !~ /^(graph-easy|Graph::Easy|yED)\z/i)
    {
    return $self->error("Format '$args->{format}' not understood by as_graphml.");
    }
  my $format = $args->{format};

  # Convert the graph to a textual representation - does not need layout().

  my $schema = "http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd";
  $schema = "http://www.yworks.com/xml/schema/graphml/1.0/ygraphml.xsd" if $format eq 'yED';
  my $y_schema = '';
  $y_schema = "\n    xmlns:y=\"http://www.yworks.com/xml/graphml\"" if $format eq 'yED';

  my $txt = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"##Y##
    xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns
     ##SCHEMA##">

  <!-- Created by Graph::Easy v##VERSION## at ##DATE## -->

EOF
;
	  
  $txt =~ s/##DATE##/scalar localtime()/e;
  $txt =~ s/##VERSION##/$Graph::Easy::VERSION/;
  $txt =~ s/##SCHEMA##/$schema/;
  $txt =~ s/##Y##/$y_schema/;

  # <key id="d0" for="node" attr.name="color" attr.type="string">
  #   <default>yellow</default>
  # </key>
  # <key id="d1" for="edge" attr.name="weight" attr.type="double"/>

  # First gather all possible attributes, then add defines for them. This
  # avoids lengthy re-definitions of attributes that aren't used:

  my %keys;

  my $tpl = '  <key id="##id##" for="##class##" attr.name="##name##" attr.type="##type##">'
      ."\n    <default>##default##</default>\n"
      ."  </key>\n";
  my $tpl_no_default = '  <key id="##id##" for="##class##" attr.name="##name##" attr.type="##type##"/>'."\n";

  # for yED:
  # <key for="node" id="d0" yfiles.type="nodegraphics"/>
  # <key attr.name="description" attr.type="string" for="node" id="d1"/>
  # <key for="edge" id="d2" yfiles.type="edgegraphics"/>
  # <key attr.name="description" attr.type="string" for="edge" id="d3"/>
  # <key for="graphml" id="d4" yfiles.type="resources"/>

  # we need to remember the mapping between attribute name and ID:
  my $ids = {};
  my $id = 'd0';

  ###########################################################################
  # first the class attributes
  for my $class (sort keys %{$self->{att}})
    {
    my $att =  $self->{att}->{$class};

    $txt .=
	$self->_graphml_attr_keys( $tpl, $tpl_no_default, $class, $att, $ids, \$id);

    }

  my @nodes = $self->sorted_nodes('name','id');

  ###########################################################################
  # now the attributes on the objects:
  for my $o (@nodes, values %{$self->{edges}})
    {
    $txt .=
	$self->_graphml_attr_keys( $tpl, $tpl_no_default, $o->class(),
				   $o->raw_attributes(), $ids, \$id);
    }
  $txt .= "\n" unless $id eq 'd0';

  my $indent = '  ';
  $txt .= $indent . '<graph id="G" edgedefault="' . $self->type() . "\">\n";

  # output graph attributes:
  $txt .= $self->_attributes_as_graphml($self,'  ',$ids->{graph});

  # output groups recursively
  my @groups = $self->groups_within(0);
  foreach my $g (@groups)
    {
    $txt .= $g->as_graphml($indent.'  ',$ids);			# marks nodes as processed if nec.
    }
 
  $indent = '    ';		
  foreach my $n (@nodes)
    {
    next if $n->{group};				# already done in a group
    $txt .= $n->as_graphml($indent,$ids);		# <node id="..." ...>
    }

  $txt .= "\n";

  foreach my $n (@nodes)
    {
    next if $n->{group};				# already done in a group

    my @out = $n->sorted_successors();
    # for all outgoing connections
    foreach my $other (@out)
      {
      # in case there exists more than one edge from $n --> $other
      my @edges = $n->edges_to($other);
      for my $edge (sort { $a->{id} <=> $b->{id} } @edges)
        {
        $txt .= $edge->as_graphml($indent,$ids);	# <edge id="..." ...>
        }
      }
    }

  $txt .= "  </graph>\n</graphml>\n";
  $txt;
  }

sub _safe_xml
  {
  # make a text XML safe
  my ($self,$txt) = @_;

  $txt =~ s/&/&amp;/g;			# quote &
  $txt =~ s/>/&gt;/g;			# quote >
  $txt =~ s/</&lt;/g;			# quote <
  $txt =~ s/"/&quot;/g;			# quote "
  $txt =~ s/'/&apos;/g;			# quote '
  $txt =~ s/\\\\/\\/g;			# "\\" to "\"

  $txt;
  }

sub _attributes_as_graphml
  {
  # output the attributes of an object
  my ($graph, $self, $indent, $ids) = @_;

  my $tpl = "$indent  <data key=\"##id##\">##value##</data>\n";
  my $att = $self->get_attributes();
  my $txt = '';
  for my $n (sort keys %$att)
    {
    next unless exists $ids->{$n};
    my $def = $self->default_attribute($n);
    next if defined $def && $def eq $att->{$n};
    my $t = $tpl;
    $t =~ s/##id##/$ids->{$n}/;
    $t =~ s/##value##/$graph->_safe_xml($att->{$n})/e;
    $txt .= $t;
    }
  $txt;
  }

#############################################################################

package Graph::Easy::Group;

use strict;

sub as_graphml
  {
  my ($self, $indent, $ids) = @_;

  my $txt = $indent . '<graph id="' . $self->_safe_xml($self->{name}) . '" edgedefault="' .
	$self->{graph}->type() . "\">\n";
  $txt .= $self->{graph}->_attributes_as_graphml($self, $indent, $ids->{graph});

  foreach my $n (values %{$self->{nodes}})
    {
    my @out = $n->sorted_successors();

    $txt .= $n->as_graphml($indent.'  ', $ids); 		# <node id="..." ...>

    # for all outgoing connections
    foreach my $other (@out)
      {
      # in case there exists more than one edge from $n --> $other
      my @edges = $n->edges_to($other);
      for my $edge (sort { $a->{id} <=> $b->{id} } @edges)
        {
        $txt .= $edge->as_graphml($indent.'  ',$ids);
        }
      $txt .= "\n" if @edges > 0;
      }
    }

  # output groups recursively
  my @groups = $self->groups_within(0);
  foreach my $g (@groups)
    {
    $txt .= $g->_as_graphml($indent.'  ',$ids);		# marks nodes as processed if nec.
    }

  # XXX TODO: edges from/to this group

  # close this group
  $txt .= $indent . "</graph>";

  $txt;
  }

#############################################################################

package Graph::Easy::Node;

use strict;

sub as_graphml
  {
  my ($self, $indent, $ids) = @_;

  my $g = $self->{graph};
  my $txt = $indent . '<node id="' . $g->_safe_xml($self->{name}) . "\">\n";

  $txt .= $g->_attributes_as_graphml($self, $indent, $ids->{node});

  $txt .= "$indent</node>\n";

  return $txt;
  }

#############################################################################

package Graph::Easy::Edge;

use strict;

sub as_graphml
  {
  my ($self, $indent, $ids) = @_;

  my $g = $self->{graph};
  my $txt = $indent . '<edge source="' . $g->_safe_xml($self->{from}->{name}) . 
		     '" target="' . $g->_safe_xml($self->{to}->{name}) . "\">\n";

  $txt .= $g->_attributes_as_graphml($self, $indent, $ids->{edge});

  $txt .= "$indent</edge>\n";

  $txt;
  }
 
1;
__END__

=head1 NAME

Graph::Easy::As_graphml - Generate a GraphML text from a Graph::Easy object

=head1 SYNOPSIS

	use Graph::Easy;
	
	my $graph = Graph::Easy->new();

	$graph->add_edge ('Bonn', 'Berlin');

	print $graph->as_graphml();

=head1 DESCRIPTION

C<Graph::Easy::As_graphml> contains just the code for converting a
L<Graph::Easy|Graph::Easy> object to a GraphML text.

=head2 Attributes

Attributes are output in the format that C<Graph::Easy> specifies. More
details about the valid attributes and their default values can be found
in the Graph::Easy online manual:

L<http://bloodgate.com/perl/graph/manual/>.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>, L<http://graphml.graphdrawing.org/>.

=head1 AUTHOR

Copyright (C) 2004 - 2008 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut

#############################################################################
# output the graph in dot-format text
#
#############################################################################

package Graph::Easy::As_graphviz;

$VERSION = '0.31';

#############################################################################
#############################################################################

package Graph::Easy;

use strict;

my $remap = {
  node => {
    'align' => undef,
    'background' => undef,   # need a way to simulate that on non-rect nodes
    'basename' => undef,
    'bordercolor' => \&_remap_color,
    'borderstyle' => \&_graphviz_remap_border_style,
    'borderwidth' => undef,
    'border' => undef,
    'color' => \&_remap_color,
    'fill' => \&_remap_color,
    'label' => \&_graphviz_remap_label,
    'pointstyle' => undef,
    'pointshape' => undef,
    'rotate' => \&_graphviz_remap_node_rotate,
    'shape' => \&_graphviz_remap_node_shape,
    'title' => 'tooltip',
    'rows' => undef,
    'columns' => undef,
    },
  edge => {
    'align' => undef,
    'arrowstyle' => \&_graphviz_remap_arrow_style,
    'background' => undef,
    'color' => \&_graphviz_remap_edge_color,
    'end' => \&_graphviz_remap_port,
    'headtitle' => 'headtooltip',
    'headlink' => 'headURL',
    'labelcolor' => \&_graphviz_remap_label_color,
    'start' => \&_graphviz_remap_port,
    'style' => \&_graphviz_remap_edge_style,
    'tailtitle' => 'tailtooltip',
    'taillink' => 'tailURL',
    'title' => 'tooltip',
    'minlen' => \&_graphviz_remap_edge_minlen,
    },
  graph => {
    align => \&_graphviz_remap_align,
    background => undef,
    bordercolor => \&_remap_color,
    borderstyle => \&_graphviz_remap_border_style,
    borderwidth => undef,
    color => \&_remap_color,
    fill => \&_remap_color,
    gid => undef,
    label => \&_graphviz_remap_label,
    labelpos => 'labelloc',
    output => undef,
    type => undef,
    },
  group => {
    align => \&_graphviz_remap_align,
    background => undef,
    bordercolor => \&_remap_color,
    borderstyle => \&_graphviz_remap_border_style,
    borderwidth => undef,
    color => \&_remap_color,
    fill => \&_remap_color,
    labelpos => 'labelloc',
    rank => undef,
    title => 'tooltip',
    },
  all => {
    arrowshape => undef,
    autolink => undef,
    autotitle => undef,
    autolabel => undef,
    class => undef,
    colorscheme => undef,
    flow => undef,
    fontsize => \&_graphviz_remap_fontsize,
    font => \&_graphviz_remap_font,
    format => undef,
    group => undef,
    link => \&_graphviz_remap_link,
    linkbase => undef,
    textstyle => undef,
    textwrap => undef,
    },
  always => {
    node	=> [ qw/borderstyle label link rotate color fill/ ],
    'node.anon' => [ qw/bordercolor borderstyle label link rotate color/ ],
    edge	=> [ qw/labelcolor label link color/ ],
    graph	=> [ qw/labelpos borderstyle label link color/ ],
    },
  # this routine will handle all custom "x-dot-..." attributes
  x => \&_remap_custom_dot_attributes,
  };

sub _remap_custom_dot_attributes
  {
  my ($self, $name, $value) = @_;

  # drop anything that is not starting with "x-dot-..."
  return (undef,undef) unless $name =~ /^x-dot-/;

  $name =~ s/^x-dot-//;			# "x-dot-foo" => "foo"
  ($name,$value);
  }

my $color_remap = {
  bordercolor => 'color',
  color => 'fontcolor',
  fill => 'fillcolor',
  };

sub _remap_color
  {
  # remap one color value
  my ($self, $name, $color, $object) = @_;

  # guard against always doing the remap even when the attribute is not set
  return (undef,undef) unless defined $color;

  if (!ref($object) && $object eq 'graph')
    {
    # 'fill' => 'bgcolor';
    $name = 'bgcolor' if $name eq 'fill';
    }

  $name = $color_remap->{$name} || $name;

  $color = $self->_color_as_hex_or_hsv($object,$color);

  ($name, $color);
  }

sub _color_as_hex_or_hsv
  {
  # Given a color in hex, hsv, hsl or rgb, will return either a hex or hsv
  # color to preserve as much precision as possible:
  my ($graph, $self, $color) = @_;

  if ($color !~ /^#/)
    {
    # HSV colors with an alpha channel are not supported by graphviz, and
    # hence converted to RGB here:
    if ($color =~ /^hsv\(([0-9\.]+),([0-9\.]+),([0-9\.]+)\)/)
      {
      # hsv(1.0,1.0,1.0) => 1.0 1.0 1.0
      $color = "$1 $2 $3";
      }
    else
      {
      my $cs = ref($self) ? $self->attribute('colorscheme') :
			$graph->attribute($self,'colorscheme');
      # red => hex
      $color = $graph->color_as_hex($color, $cs);
      }
    }

  $color;
  }

sub _graphviz_remap_align
  {
  my ($self, $name, $style) = @_;

  my $s = lc(substr($style,0,1));		# 'l', 'r', or 'c'

  ('labeljust', $s);
  }

sub _graphviz_remap_edge_minlen
  {
  my ($self, $name, $len) = @_;

  $len = int(($len + 1) / 2);
  ($name, $len);
  }

sub _graphviz_remap_edge_color
  {
  my ($self, $name, $color, $object) = @_;

  my $style = ref($object) ? 
    $object->attribute('style') : 
    $self->attribute('edge','style');

  if (!defined $color)
    {
    $color = ref($object) ? 
      $object->attribute('color') : 
      $self->attribute('edge','color');
    }

  $color = '#000000' unless defined $color;
  $color = $self->_color_as_hex_or_hsv($object, $color);

  $color = $color . ':' . $color	# 'red:red'
    if $style =~ /^double/;

  ($name, $color);
  }

sub _graphviz_remap_edge_style
  {
  my ($self, $name, $style) = @_;

  # valid output styles are: solid dashed dotted bold invis

  $style = 'solid' unless defined $style;

  $style = 'dotted' if $style =~ /^dot-/;	# dot-dash, dot-dot-dash
  $style = 'dotted' if $style =~ /^wave/;	# wave

  # double lines will be handled in the color attribute as "color:color"
  $style = 'solid' if $style eq 'double';	# double
  $style = 'dashed' if $style =~ /^double-dash/;

  $style = 'invis' if $style eq 'invisible';	# invisible

  # XXX TODO: These should be (2, 0.5em, 1em) instead of 2,5,11
  $style = 'setlinewidth(2), dashed' if $style =~ /^bold-dash/;
  $style = 'setlinewidth(5)' if $style =~ /^broad/;
  $style = 'setlinewidth(11)' if $style =~ /^wide/;
  
  return (undef, undef) if $style eq 'solid';	# default style can be suppressed

  ($name, $style);
  }

sub _graphviz_remap_node_rotate
  {
  my ($graph, $name, $angle, $self) = @_;

  # do this only for objects, not classes 
  return (undef,undef) unless ref($self) && defined $angle;

  return (undef,undef) if $angle == 0;

  # despite what the manual says, dot rotates counter-clockwise, so fix that
  $angle = 360 - $angle;

  ('orientation', $angle);
  }

sub _graphviz_remap_port
  {
  my ($graph, $name, $side, $self) = @_;

  # do this only for objects, not classes 
  return (undef,undef) unless ref($self) && defined $side;

  # XXX TODO
  # remap relative ports (front etc) to "south" etc

  # has a specific port, aka shared a port with another edge
  return (undef, undef) if $side =~ /,/;

  $side = $graph->_flow_as_side($self->flow(),$side);

  $side = substr($side,0,1);	# "south" => "s"

  my $n = 'tailport'; $n = 'headport' if $name eq 'end';

  ($n, $side);
  }

sub _graphviz_remap_font
  {
  # Remap the font names
  my ($self, $name, $style) = @_;

  # XXX TODO: "times" => "Times.ttf" ?
  ('fontname', $style);
  }

sub _graphviz_remap_fontsize
  {
  # make sure the fontsize is in pixel or percent
  my ($self, $name, $style) = @_;

  # XXX TODO: This should be actually 1 em
  my $fs = '11';

  if ($style =~ /^([\d\.]+)em\z/)
    {
    $fs = $1 * 11;
    }
  elsif ($style =~ /^([\d\.]+)%\z/)
    {
    $fs = ($1 / 100) * 11;
    }
  # this is discouraged:
  elsif ($style =~ /^([\d\.]+)px\z/)
    {
    $fs = $1;
    }
  else
    {
    $self->_croak("Illegal font-size '$style'");
    }

  # font-size => fontsize
  ('fontsize', $fs);
  }

sub _graphviz_remap_border_style
  {
  my ($self, $name, $style, $node) = @_;

  my $shape = '';
  $shape = ($node->attribute('shape') || '') if ref($node);

  # some shapes don't need a border:
  return (undef,undef) if $shape =~ /^(none|invisible|img|point)\z/;

  $style = $node->attribute('borderstyle') unless defined $style;
 
  # valid styles are: solid dashed dotted bold invis

  $style = '' unless defined $style;

  $style = 'dotted' if $style =~ /^dot-/;	# dot-dash, dot-dot-dash
  $style = 'dashed' if $style =~ /^double-/;	# double-dash
  $style = 'dotted' if $style =~ /^wave/;	# wave

  # borderstyle double will be handled extra with peripheries=2 later
  $style = 'solid' if $style eq 'double';

  # XXX TODO: These should be (2, 0.5em, 1em) instead of 2,5,11
  $style = 'setlinewidth(2)' if $style =~ /^bold/;
  $style = 'setlinewidth(5)' if $style =~ /^broad/;
  $style = 'setlinewidth(11)' if $style =~ /^wide/;

  # "solid 0px" => "none"
  my $w = 0; $w = $node->attribute('borderwidth') if (ref($node) && $style ne 'none');
  $style = 'none' if $w == 0;

  my @rc;
  if ($style eq 'none')
    {
    my $fill = 'white'; $fill = $node->color_attribute('fill') if ref($node);
    $style = 'filled'; @rc = ('color', $fill);
    }
  
  # default style can be suppressed
  return (undef, undef) if $style =~ /^(|solid)\z/ && $shape ne 'rounded';

  # for graphviz v2.4 and up
  $style = 'filled' if $style eq 'solid';
  $style = 'filled,'.$style unless $style eq 'filled';
  $style = 'rounded,'.$style if $shape eq 'rounded' && $style ne 'none';

  $style =~ s/,\z//;		# "rounded," => "rounded"

  push @rc, 'style', $style;
  @rc;
  }

sub _graphviz_remap_link
  {
  my ($self, $name, $l, $object) = @_;

  # do this only for objects, not classes 
  return (undef,undef) unless ref($object);
  
  $l = $object->link() unless defined $l;

  ('URL', $l);
  }

sub _graphviz_remap_label_color
  {
  my ($graph, $name, $color, $self) = @_;

  # do this only for objects, not classes 
  return (undef,undef) unless ref($self);
  
  # no label => no color nec.
  return (undef, $color) if ($self->label()||'') eq '';

  $color = $self->raw_attribute('labelcolor') unless defined $color;

  # the label color falls back to the edge color
  $color = $self->attribute('color') unless defined $color;

  $color = $graph->_color_as_hex_or_hsv($self,$color);

  ('fontcolor', $color);
  }

sub _graphviz_remap_node_shape
  {
  my ($self, $name, $style, $object) = @_;

  # img needs no shape, and rounded is handled as style
  return (undef,undef) if $style =~ /^(img|rounded)\z/;

  # valid styles are: solid dashed dotted bold invis

  my $s = $style;
  $s = 'plaintext' if $style =~ /^(invisible|none|point)\z/;

  if (ref($object))
    {
    my $border = $object->attribute('borderstyle');
    $s = 'plaintext' if $border eq 'none';
    }

  ($name, $s);
  }

sub _graphviz_remap_arrow_style
  {
  my ($self, $name, $style) = @_;

  my $s = 'normal';
 
  $s = $style if $style =~ /^(none|open)\z/;
  $s = 'empty' if $style eq 'closed';

  my $n = 'arrowhead';
  $n = 'arrowtail' if $self->{_flip_edges};

  ($n, $s);
  }

sub _graphviz_remap_label
  {
  my ($self, $name, $label, $node) = @_;

  my $s = $label;

  # call label() to handle thinks like "autolabel: 15" properly
  $s = $node->label() if ref($node);

  if (ref($node))
    {
    # remap all "\n" and "\c" to either "\l" or "\r", depending on align
    my $align = $node->attribute('align');
    my $next_line = '\n';
    # the align of the line-ends counts for the line _before_ them, so
    # add one more to fix the last line
    $next_line = '\l', $s .= '\l' if $align eq 'left';
    $next_line = '\r', $s .= '\r' if $align eq 'right';

    $s =~ s/(^|[^\\])\\n/$1$next_line/g;	# \n => align
    }

  $s =~ s/(^|[^\\])\\c/$1\\n/g;			# \c => \n (for center)

  my $shape = 'rect';
  $shape = ($node->attribute('shape') || '') if ref($node);

  # only for nodes and when they have a "shape: img"
  if ($shape eq 'img')
    {
    my $s = '<<TABLE BORDER="0"><TR><TD><IMG SRC="##url##" /></TD></TR></TABLE>>';

    my $url = $node->label();
    $url =~ s/\s/\+/g;				# space
    $url =~ s/'/%27/g;				# replace quotation marks
    $s =~ s/##url##/$url/g;
    }

  ($name, $s);
  }

#############################################################################

sub _att_as_graphviz
  {
  # convert a hash with attribute => value mappings to a string
  my ($self, $out) = @_;

  my $att = '';
  for my $atr (keys %$out)
    {
    my $v = $out->{$atr};
    $v =~ s/\n/\\n/g;

    $v = '"' . $v . '"' if $v !~ /^[a-z0-9A-Z]+\z/;	# quote if nec.

    # convert "x-dot-foo" to "foo". Special case "K":
    my $name = $atr; $name =~ s/^x-dot-//; $name = 'K' if $name eq 'k';

    $att .= "  $name=$v,\n";
    }

  $att =~ s/,\n\z/ /;			# remove last ","
  if ($att ne '')
    {
    # the following makes short, single definitions to fit on one line
    if ($att !~ /\n.*\n/ && length($att) < 40)
      {
      $att =~ s/\n/ /; $att =~ s/( )+/ /g;
      }
    else
      {
      $att =~ s/\n/\n  /g;
      $att = "\n  $att";
      }
    }
  $att;
  }

sub _generate_group_edge
  {
  # Given an edge (from/to at least one group), generate the graphviz code
  my ($self, $e, $indent) = @_;

  my $edge_att = $e->attributes_as_graphviz();

  my $a = ''; my $b = '';
  my $from = $e->{from};
  my $to = $e->{to};

  ($from,$to) = ($to,$from) if $self->{_flip_edges};
  if ($from->isa('Graph::Easy::Group'))
    {
    # find an arbitray node inside the group
    my ($n, $v) = each %{$from->{nodes}};
    
    $a = 'ltail="cluster' . $from->{id}.'"';	# ltail=cluster0
    $from = $v;
    }

  # XXX TODO:
  # this fails for empty groups
  if ($to->isa('Graph::Easy::Group'))
    {
    # find an arbitray node inside the group
    my ($n, $v) = each %{$to->{nodes}};
    
    $b = 'lhead="cluster' . $to->{id}.'"';	# lhead=cluster0
    $to = $v;
    }

  my $other = $to->_graphviz_point();
  my $first = $from->_graphviz_point();

  $e->{_p} = undef;				# mark as processed

  my $att = $a; 
  $att .= ', ' . $b if $b ne ''; $att =~ s/^,//;
  if ($att ne '')
    {
    if ($edge_att eq '')
      {
      $edge_att = " [ $att ]";
      }
    else
      {
      $edge_att =~ s/ \]/, $att \]/;
      }
    }

  "$indent$first $self->{edge_type} $other$edge_att\n";		# return edge text
  }

sub _insert_edge_attribute
  {
  # insert an additional attribute into an edge attribute string
  my ($self, $att, $new_att) = @_;

  return '[ $new_att ]' if $att eq '';		# '' => '[ ]'

  # remove any potential old attribute with the same name
  my $att_name = $new_att; $att_name =~ s/=.*//;
  $att =~ s/$att_name=("[^"]+"|[^\s]+)//;
  
  # insert the new attribute at the end
  $att =~ s/\s?\]/,$new_att ]/;

  $att;
  }

sub _suppress_edge_attribute
  {
  # remove the named attribute from the edge attribute string
  my ($self, $att, $sup_att) = @_;

  $att =~ s/$sup_att=("(\\"|[^"])*"|[^\s\n,;]+)[,;]?//;
  $att;
  }

sub _generate_edge
  {
  # Given an edge, generate the graphviz code for it
  my ($self, $e, $indent) = @_;

  # skip links from/to groups, these will be done later
  return '' if 
    $e->{from}->isa('Graph::Easy::Group') ||
    $e->{to}->isa('Graph::Easy::Group');

  my $invis = $self->{_graphviz_invis};

  # attributes for invisible helper nodes (the color will be filled in from the edge color)
  my $inv       = ' [ label="",shape=none,style=filled,height=0,width=0,fillcolor="';

  my $other = $e->{to}->_graphviz_point();
  my $first = $e->{from}->_graphviz_point();

  my $edge_att = $e->attributes_as_graphviz();
  my $txt = '';

  my $modify_edge = 0;
  my $suppress_start = (!$self->{_flip_edges} ? 'arrowtail=none' : 'arrowhead=none');
  my $suppress_end   = ( $self->{_flip_edges} ? 'arrowtail=none' : 'arrowhead=none');
  my $suppress;

  # if the edge has a shared start/end port
  if ($e->has_ports())
    {
    my @edges = ();

    my ($side,@port) = $e->port('start');
    @edges = $e->{from}->edges_at_port('start',$side,@port) if defined $side && @port > 0;

    if (@edges > 1)					# has strict port
      {
      # access the invisible node
      my $sp = $e->port('start');
      my $key = "$e->{from}->{name},start,$sp";
      my $invis_id = $invis->{$key};
      $suppress = $suppress_start;
      if (!defined $invis_id)
	{
	# create the invisible helper node
	# find a name for it, carefully avoiding names of other nodes: 
	$self->{_graphviz_invis_id}++ while (defined $self->node($self->{_graphviz_invis_id}));
	$invis_id = $self->{_graphviz_invis_id}++;

	# output the helper node
	my $e_color = $e->color_attribute('color');
	$txt .= $indent . "$invis_id$inv$e_color\" ]\n";
	my $e_att = $self->_insert_edge_attribute($edge_att,$suppress_end);
	$e_att = $self->_suppress_edge_attribute($e_att,'label');
	my $before = ''; my $after = ''; my $i = $indent;
	if ($e->{group})
	  {
	  $before = $indent . 'subgraph "cluster' . $e->{group}->{id} . "\" {\n";
	  $after = $indent . "}\n";
	  $i = $indent . $indent;
	  }
	if ($self->{_flip_edges})
	  {
	  $txt .= $before . $i . "$invis_id $self->{_edge_type} $first$e_att\n" . $after;
	  }
	else
	  {
	  $txt .= $before . $i . "$first $self->{_edge_type} $invis_id$e_att\n" . $after;
	  }
	$invis->{$key} = $invis_id;		# mark as created
	}
      # "joint0" etc
      $first = $invis_id;
      $modify_edge++;
      }

    ($side,@port) = $e->port('end');
    @edges = ();
    @edges = $e->{to}->edges_at_port('end',$side,@port) if defined $side && @port > 0;
    if (@edges > 1)
      {
      my $ep = $e->port('end');
      my $key = "$e->{to}->{name},end,$ep";
      my $invis_id = $invis->{$key};
      $suppress = $suppress_end;

      if (!defined $invis_id)
	{
	# create the invisible helper node
	# find a name for it, carefully avoiding names of other nodes:
	$self->{_graphviz_invis_id}++ while (defined $self->node($self->{_graphviz_invis_id}));
	$invis_id = $self->{_graphviz_invis_id}++;

        my $e_att = $self->_insert_edge_attribute($edge_att,$suppress_start);
	# output the helper node
	my $e_color = $e->color_attribute('color');
	$txt .= $indent . "$invis_id$inv$e_color\" ]\n";
	my $before = ''; my $after = ''; my $i = $indent;
	if ($e->{group})
	  {
	  $before = $indent . 'subgraph "cluster' . $e->{group}->{id} . "\" {\n";
	  $after = $indent . "}\n";
	  $i = $indent . $indent;
	  }
	if ($self->{_flip_edges})
	  {
	  $txt .= $before . $i . "$other $self->{_edge_type} $invis_id$e_att\n" . $after;
	  }
	else
	  {
	  $txt .= $before . $i . "$invis_id $self->{_edge_type} $other$e_att\n" . $after;
	  }
	$invis->{$key} = $invis_id;			# mark as output
	}
      # "joint1" etc
      $other = $invis_id;
      $modify_edge++;
      }
    }

  ($other,$first) = ($first,$other) if $self->{_flip_edges};

  $e->{_p} = undef;				# mark as processed

  $edge_att = $self->_insert_edge_attribute($edge_att,$suppress)
    if $modify_edge;

  $txt . "$indent$first $self->{_edge_type} $other$edge_att\n";		# return edge text
  }

sub _order_group 
  {
  my ($self,$group) = @_;
  $group->{_order}++;
  for my $sg (values %{$group->{groups}})
	{
		$self->_order_group($sg);
	}
  }


sub _as_graphviz_group 
  {
  my ($self,$group) = @_;

  my $txt = '';
    # quote special chars in group name
    my $name = $group->{name}; $name =~ s/([\[\]\(\)\{\}\#"])/\\$1/g;

   return if $group->{_p};
    # output group attributes first
    my $indent = '  ' x ($group->{_order});
    $txt .= $indent."subgraph \"cluster$group->{id}\" {\n${indent}label=\"$name\";\n";

	for my $sg (values %{$group->{groups}})
	{
		#print '--'.$sg->{name}."\n";
		$txt .= $self->_as_graphviz_group($sg,$indent);
		$sg->{_p} = 1;
	}
    # Make a copy of the attributes, including our class attributes:
    my $copy = {};
    my $attribs = $group->get_attributes();

    for my $a (keys %$attribs)
      {
      $copy->{$a} = $attribs->{$a};
      }
    # set some defaults
    $copy->{'borderstyle'} = 'solid' unless defined $copy->{'borderstyle'};

    my $out = $self->_remap_attributes( $group->class(), $copy, $remap, 'noquote');

    # Set some defaults:
    $out->{fillcolor} = '#a0d0ff' unless defined $out->{fillcolor};
    $out->{labeljust} = 'l' unless defined $out->{labeljust};

    my $att = '';
    # we need to output style first ("filled" and "color" need come later)
    for my $atr (reverse sort keys %$out)
      {
      my $v = $out->{$atr};
      $v = '"' . $v . '"' if $v !~ /^[a-z0-9A-Z]+\z/;	# quote if nec.

      # convert "x-dot-foo" to "foo". Special case "K":
      my $name = $atr; $name =~ s/^x-dot-//; $name = 'K' if $name eq 'k';

      $att .= $indent."$name=$v;\n";
      }
    $txt .= $att . "\n" if $att ne '';
 
    # output nodes (w/ or w/o attributes) in that group
    for my $n ($group->sorted_nodes())
      {
      # skip nodes that are relativ to others (these are done as part
      # of the HTML-like label of their parent)
      next if $n->{origin};

      my $att = $n->attributes_as_graphviz();
      $n->{_p} = undef;			# mark as processed
      $txt .= $indent . $n->as_graphviz_txt() . $att . "\n";
      }

    # output node connections in this group
    for my $e (values %{$group->{edges}})
      {
      next if exists $e->{_p};
      $txt .= $self->_generate_edge($e, $indent);
      }

    $txt .= $indent."}\n";
   
   return $txt;
  }

sub _as_graphviz
  {
  my ($self) = @_;

  # convert the graph to a textual representation
  # does not need a layout() beforehand!

  my $name = "GRAPH_" . ($self->{gid} || '0');

  my $type = $self->attribute('type');
  $type = $type eq 'directed' ? 'digraph' : 'graph';	# directed or undirected?

  $self->{_edge_type} = $type eq 'digraph' ? '->' : '--';	# "a -- b" vs "a -> b"

  my $txt = "$type $name {\n\n" .
            "  // Generated by Graph::Easy $Graph::Easy::VERSION" .
	    " at " . scalar localtime() . "\n\n";


  my $flow = $self->attribute('graph','flow');
  $flow = 'east' unless defined $flow;

  $flow = Graph::Easy->_direction_as_number($flow);

  # for LR, BT layouts
  $self->{_flip_edges} = 0;
  $self->{_flip_edges} = 1 if $flow == 270 || $flow == 0;
  
  my $groups = $self->groups();

  # to keep track of invisible helper nodes
  $self->{_graphviz_invis} = {};
  # name for invisible helper nodes
  $self->{_graphviz_invis_id} = 'joint0';

  # generate the class attributes first
  my $atts =  $self->{att};
  # It is not possible to set attributes for groups in the DOT language that way
  for my $class (qw/edge graph node/)
    {
    next if $class =~ /\./;		# skip subclasses

    my $out = $self->_remap_attributes( $class, $atts->{$class}, $remap, 'noquote');

    # per default, our nodes are rectangular, white, filled boxes
    if ($class eq 'node')
      {
      $out->{shape} = 'box' unless $out->{shape}; 
      $out->{style} = 'filled' unless $out->{style};
      $out->{fontsize} = '11' unless $out->{fontsize};
      $out->{fillcolor} = 'white' unless $out->{fillcolor};
      }
    elsif ($class eq 'graph')
      {
      $out->{rankdir} = 'LR' if $flow == 90 || $flow == 270;
      $out->{labelloc} = 'top' if defined $out->{label} && !defined $out->{labelloc};
      $out->{style} = 'filled' if $groups > 0;
      }
    elsif ($class eq 'edge')
      {
      $out->{dir} = 'back' if $flow == 270 || $flow == 0;
      my ($name,$style) = $self->_graphviz_remap_arrow_style('',
        $self->attribute('edge','arrowstyle') );
      $out->{$name} = $style;
      }

    my $att = $self->_att_as_graphviz($out);

    $txt .= "  $class [$att];\n" if $att ne '';
    }

  $txt .= "\n" if $txt ne '';		# insert newline

  ###########################################################################
  # output groups as subgraphs

  # insert the edges into the proper group
  $self->_edges_into_groups() if $groups > 0;

  # output the groups (aka subclusters)
  for my $group (values %{$self->{groups}})
  {
   $self->_order_group($group);
  }
  for my $group (sort { $a->{_order} cmp $b->{_order} } values %{$self->{groups}})
  {
    $txt .= $self->_as_graphviz_group($group) || '';
  }

  my $root = $self->attribute('root');
  $root = '' unless defined $root;

  my $count = 0;
  # output nodes with attributes first, sorted by their name
  for my $n (sort { $a->{name} cmp $b->{name} } values %{$self->{nodes}})
    {
    next if exists $n->{_p};
    # skip nodes that are relativ to others (these are done as part
    # of the HTML-like label of their parent)
    next if $n->{origin};
    my $att = $n->attributes_as_graphviz($root);
    if ($att ne '')
      {
      $n->{_p} = undef;			# mark as processed
      $count++;
      $txt .= "  " . $n->as_graphviz_txt() . $att . "\n"; 
      }
    }
 
  $txt .= "\n" if $count > 0;		# insert a newline

  my @nodes = $self->sorted_nodes();

  # output the edges
  foreach my $n (@nodes)
    {
    my @out = $n->successors();
    my $first = $n->as_graphviz_txt();
    if ((@out == 0) && ( (scalar $n->predecessors() || 0) == 0))
      {
      # single node without any connections (unless already output)
      $txt .= "  " . $first . "\n" unless exists $n->{_p} || $n->{origin};
      }
    # for all outgoing connections
    foreach my $other (reverse @out)
      {
      # in case there is more than one edge going from N to O
      my @edges = $n->edges_to($other);
      foreach my $e (@edges)
        {
        next if exists $e->{_p};
        $txt .= $self->_generate_edge($e, '  ');
        }
      }
    }

  # insert now edges between groups (clusters/subgraphs)

  foreach my $e (values %{$self->{edges}})
    {
    $txt .= $self->_generate_group_edge($e, '  ') 
     if $e->{from}->isa('Graph::Easy::Group') ||
        $e->{to}->isa('Graph::Easy::Group');
    }

  # clean up
  for my $n ( values %{$self->{nodes}}, values %{$self->{edges}})
    {
    delete $n->{_p};
    }
  delete $self->{_graphviz_invis};		# invisible helper nodes for joints
  delete $self->{_flip_edges};
  delete $self->{_edge_type};

  $txt .  "\n}\n";				# close the graph
  }

package Graph::Easy::Node;

sub attributes_as_graphviz
  {
  # return the attributes of this node as text description
  my ($self, $root) = @_;
  $root = '' unless defined $root;

  my $att = '';
  my $class = $self->class();

  return '' unless ref $self->{graph};

  my $g = $self->{graph};

  # get all attributes, excluding the class attributes
  my $a = $self->raw_attributes();

  # add the attributes that are listed under "always":
  my $attr = $self->{att};
  my $base_class = $class; $base_class =~ s/\..*//;
  my $list = $remap->{always}->{$class} || $remap->{always}->{$base_class};
  for my $name (@$list)
    {
    # for speed, try to look it up directly

    # look if we have a code ref:
    if ( ref($remap->{$base_class}->{$name}) ||
         ref($remap->{all}->{$name}) )
      {
      $a->{$name} = $self->raw_attribute($name);
      if (!defined $a->{$name})
        {
        my $b_attr = $g->get_attribute($base_class,$name);
        my $c_attr = $g->get_attribute($class,$name);
        if (defined $b_attr && defined $c_attr && $b_attr ne $c_attr)
          {
          $a->{$name} = $c_attr;
          $a->{$name} = $b_attr unless defined $a->{$name};
          }
        }
      }
    else
      {
      $a->{$name} = $attr->{$name};
      $a->{$name} = $self->attribute($name) unless defined $a->{$name} && $a->{$name} ne 'inherit';
      }
    }

  $a = $g->_remap_attributes( $self, $a, $remap, 'noquote');

  # do not needlessly output labels:
  delete $a->{label} if !$self->isa('Graph::Easy::Edge') &&		# not an edge
	exists $a->{label} && $a->{label} eq $self->{name};

  # generate HTML-like labels for nodes with children, but do so only
  # for the node which is not itself a child
  if (!$self->{origin} && $self->{children} && keys %{$self->{children}} > 0)
    {
    #print "Generating HTML-like label for $self->{name}\n";
    $a->{label} = $self->_html_like_label();
    # make Graphviz avoid the outer border
    $a->{shape} = 'none';
    }

  # bidirectional and undirected edges
  if ($self->{bidirectional})
    {
    delete $a->{dir};
    my ($n,$s) = Graph::Easy::_graphviz_remap_arrow_style(
	$self,'', $self->attribute('arrowstyle'));
    $a->{arrowhead} = $s; 
    $a->{arrowtail} = $s; 
    }
  if ($self->{undirected})
    {
    delete $a->{dir};
    $a->{arrowhead} = 'none'; 
    $a->{arrowtail} = 'none'; 
    }

  if (!$self->isa_cell())
    {
    # borderstyle: double:
    my $style = $self->attribute('borderstyle');
    my $w = $self->attribute('borderwidth');
    $a->{peripheries} = 2 if $style =~ /^double/ && $w > 0;
    }

  # For nodes with shape plaintext, set the fillcolor to the background of
  # the graph/group
  my $shape = $a->{shape} || 'rect';
  if ($class =~ /node/ && $shape eq 'plaintext')
    {
    my $p = $self->parent();
    $a->{fillcolor} = $p->attribute('fill');
    $a->{fillcolor} = 'white' if $a->{fillcolor} eq 'inherit';
    }

  $shape = $self->attribute('shape') unless $self->isa_cell();

  # for point-shaped nodes, include the point as label and set width/height
  if ($shape eq 'point')
    {
    require Graph::Easy::As_ascii;		# for _u8 and point-style

    my $style = $self->_point_style( 
	$self->attribute('pointshape'), 
	$self->attribute('pointstyle') );

    $a->{label} = $style;
    # for point-shaped invisible nodes, set height/width = 0
    $a->{width} = 0, $a->{height} = 0 if $style eq '';  
    }
  if ($shape eq 'invisible')
    {
    $a->{label} = ' ';
    }

  $a->{rank} = '0' if $root ne '' && $root eq $self->{name};

  # create the attributes as text:
  for my $atr (sort keys %$a)
    {
    my $v = $a->{$atr};
    $v =~ s/"/\\"/g;		# '2"' => '2\"'

    # don't quote labels like "<<TABLE.."
    if ($atr eq 'label' && $v =~ /^<<TABLE/)
      {
      my $va = $v; $va =~ s/\\"/"/g;		# unescape \"
      $att .= "$atr=$va, ";
      next;
      }

    $v = '"' . $v . '"' if $v !~ /^[a-z0-9A-Z]+\z/
	  || $atr eq 'URL';	# quote if nec.

    # convert "x-dot-foo" to "foo". Special case "K":
    my $name = $atr; $name =~ s/^x-dot-//; $name = 'K' if $name eq 'k';

    $att .= "$name=$v, ";
    }
  $att =~ s/,\s$//;             # remove last ","

  # generate attribute text if nec.
  $att = ' [ ' . $att . ' ]' if $att ne '';

  $att;
  }

sub _html_like_label
  {
  # Generate a HTML-like label from one node with its relative children
  my ($self) = @_;

  my $cells = {};
  my $rc = $self->_do_place(0,0, { cells => $cells, cache => {} } );

  # <TABLE BORDER="0" CELLPADDING="0" CELLSPACING="0"><TR><TD>Name2</TD></TR><TR><TD
  # ALIGN ="LEFT" BALIGN="LEFT" PORT="E4">Somewhere<BR/>test1<BR>test</TD></TR></TABLE>

  my $label = '<<TABLE BORDER="0"><TR>';

  my $old_y = 0; my $old_x = 0;
  # go through all children, and sort them by Y then X coordinate
  my @cells = ();
  for my $cell (sort {
	my ($ax,$ay) = split /,/,$a;
	my ($bx,$by) = split /,/,$b;
	$ay <=> $by or $ax <=> $bx; } keys %$cells )
    {
    #print "cell $cell\n";
    my ($x,$y) = split /,/, $cell;
    if ($y > $old_y)
      {
      $label .= '</TR><TR>'; $old_x = 0;
      }
    my $n = $cells->{$cell};
    my $l = $n->label();
    $l =~ s/\\n/<BR\/>/g;
    my $portname = $n->{autosplit_portname};
    $portname = $n->label() unless defined $portname;
    my $name = $self->{name};
    $portname =~ s/\"/\\"/g;			# quote "
    $name =~ s/\"/\\"/g;			# quote "
    # store the "nodename:portname" combination for potential edges
    $n->{_graphviz_portname} = '"' . $name . '":"' . $portname . '"';
    if (($x - $old_x) > 0)
      {
      # need some spacers
      $label .= '<TD BORDER="0" COLSPAN="' . ($x - $old_x) . '"></TD>';
      } 
    $label .= '<TD BORDER="1" PORT="' . $portname . '">' . $l . '</TD>';
    $old_y = $y + $n->{cy}; $old_x = $x + $n->{cx};
    }

  # return "<<TABLE.... /TABLE>>"
  $label . '</TR></TABLE>>';
  }

sub _graphviz_point
  {
  # return the node as the target/source of an edge
  # either "name", or "name:port"
  my ($n) = @_;

  return $n->{_graphviz_portname} if exists $n->{_graphviz_portname};

  $n->as_graphviz_txt();
  }

sub as_graphviz_txt
  {
  # return the node itself (w/o attributes) as graphviz representation
  my $self = shift;

  my $name = $self->{name};

  # escape special chars in name (including doublequote!)
  $name =~ s/([\[\]\(\)\{\}"])/\\$1/g;

  # quote if necessary:
  # 2, A, A2, "2A", "2 A" etc
  $name = '"' . $name . '"' if $name !~ /^([a-zA-Z_]+|\d+)\z/ ||
 	$name =~ /^(subgraph|graph|node|edge|strict)\z/i;	# reserved keyword

  $name;
  }
 
1;
__END__

=head1 NAME

Graph::Easy::As_graphviz - Generate graphviz description from graph object

=head1 SYNOPSIS

	use Graph::Easy;
	
	my $graph = Graph::Easy->new();

	my $bonn = Graph::Easy::Node->new(
		name => 'Bonn',
	);
	my $berlin = Graph::Easy::Node->new(
		name => 'Berlin',
	);

	$graph->add_edge ($bonn, $berlin);

	print $graph->as_graphviz();

	# prints something like:

	# digraph NAME { Bonn -> Berlin }

=head1 DESCRIPTION

C<Graph::Easy::As_graphviz> contains just the code for converting a
L<Graph::Easy|Graph::Easy> object to a textual description suitable for
feeding it to Graphviz programs like C<dot>.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>, L<Graph::Easy::Parser::Graphviz>.

=head1 AUTHOR

Copyright (C) 2004 - 2008 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut
#############################################################################
# Output an Graph::Easy object as textual description
#

package Graph::Easy::As_txt;

$VERSION = '0.15';

#############################################################################
#############################################################################

package Graph::Easy;

use strict;

sub _as_txt
  {
  my ($self) = @_;

  # Convert the graph to a textual representation - does not need layout().
  $self->_assign_ranks();

  # generate the class attributes first
  my $txt = '';
  my $att =  $self->{att};
  for my $class (sort keys %$att)
    {

    my $out = $self->_remap_attributes(
     $class, $att->{$class}, {}, 'noquote', 'encode' );

    my $att = '';
    for my $atr (sort keys %$out)
      {
      # border is handled special below
      next if $atr =~ /^border/;
      $att .= "  $atr: $out->{$atr};\n";
      }

    # edges do not have a border
    if ($class !~ /^edge/)
      {
      my $border = $self->border_attribute($class) || '';

      # 'solid 1px #000000' =~ /^solid/;
      # 'solid 1px #000000' =~ /^solid 1px #000000/;
      $border = '' if $self->default_attribute($class,'border') =~ /^$border/;

      $att .= "  border: $border;\n" if $border ne '';
      }

    if ($att ne '')
      {
      # the following makes short, single definitions to fit on one line
      if ($att !~ /\n.*\n/ && length($att) < 40)
        {
        $att =~ s/\n/ /; $att =~ s/^  / /;
        }
      else
        {
        $att = "\n$att";
        }
      $txt .= "$class {$att}\n";
      }
    }

  $txt .= "\n" if $txt ne '';		# insert newline

  my @nodes = $self->sorted_nodes('name','id');

  my $count = 0;
  # output nodes with attributes first, sorted by their name
  foreach my $n (@nodes)
    {
    $n->{_p} = undef;			# mark as not yet processed
    my $att = $n->attributes_as_txt();
    if ($att ne '')
      {
      $n->{_p} = 1;			# mark as processed
      $count++;
      $txt .= $n->as_pure_txt() . $att . "\n"; 
      }
    }
 
  $txt .= "\n" if $count > 0;		# insert a newline

  # output groups first, with their nodes
  foreach my $gn (sort keys %{$self->{groups}})
    {
    my $group = $self->{groups}->{$gn};
    $txt .= $group->as_txt();		# marks nodes as processed if nec.
    $count++;
    }

  # XXX TODO:
  # Output all nodes with rank=0 first, and also follow their successors
  # What is left will then be done next, with rank=1 etc.
  # This output order let's us output node chains in compact form as:
  # [A]->[B]->[C]->[D]
  # [B]->[E]
  # instead of having:
  # [A]->[B]
  # [B]->[E]
  # [B]->[C] etc
 
  @nodes = $self->sorted_nodes('rank','name');
  foreach my $n (@nodes)
    {
    my @out = $n->sorted_successors();
    my $first = $n->as_pure_txt(); 		# [ A | B ]
    if ( defined $n->{autosplit} || ((@out == 0) && ( (scalar $n->predecessors() || 0) == 0)))
      {
      # single node without any connections (unless already output)
      next if exists $n->{autosplit} && !defined $n->{autosplit};
      $txt .= $first . "\n" unless defined $n->{_p};
      }

    $first = $n->_as_part_txt();		# [ A.0 ]
    # for all outgoing connections
    foreach my $other (@out)
      {
      # in case there exists more than one edge from $n --> $other
      my @edges = $n->edges_to($other);
      for my $edge (sort { $a->{id} <=> $b->{id} } @edges)
        {
        $txt .= $first . $edge->as_txt() . $other->_as_part_txt() . "\n";
        }
      }
    }

  foreach my $n (@nodes)
    {
    delete $n->{_p};			# clean up
    }

  $txt;
  }

#############################################################################

package Graph::Easy::Group;

use strict;

sub as_txt
  {
  my $self = shift;

  my $n = '';
  if (!$self->isa('Graph::Easy::Group::Anon'))
    {
    $n = $self->{name};
    # quote special chars in name
    $n =~ s/([\[\]\(\)\{\}\#])/\\$1/g;
    $n = ' ' . $n;
    }

  my $txt = "($n";

  $n = $self->{nodes};

  $txt .= (keys %$n > 0 ? "\n" : ' ');
  for my $name ( sort keys %$n )
    {
    $n->{$name}->{_p} = 1;                              # mark as processed
    $txt .= '  ' . $n->{$name}->as_pure_txt() . "\n";
    }
  $txt .= ")" . $self->attributes_as_txt() . "\n\n";

  # insert all the edges of the group

  #
  $txt;
  }

#############################################################################

package Graph::Easy::Node;

use strict;

sub attributes_as_txt
  {
  # return the attributes of this node as text description
  my ($self, $remap) = @_;

  # nodes that were autosplit
  if (exists $self->{autosplit})
    {
    # other nodes are invisible in as_txt: 
    return '' unless defined $self->{autosplit};
    # the first one might have had a label set
    }

  my $att = '';
  my $class = $self->class();
  my $g = $self->{graph};

  # XXX TODO: remove atttributes that are simple the default attributes

  my $attributes = $self->{att};
  if (exists $self->{autosplit})
    {
    # for the first node in a row of autosplit nodes, we need to create
    # the correct attributes, e.g. "silver|red|" instead of just silver:
    my $basename = $self->{autosplit_basename};
    $attributes = { };

    my $parts = $self->{autosplit_parts};
    # gather all possible attribute names, otherwise an attribute set
    # on only one part (like via "color: |red;" would not show up:
    my $names = {};
    for my $child ($self, @$parts)
      {
      for my $k (keys %{$child->{att}})
        {
        $names->{$k} = undef;
        }
      }

    for my $k (keys %$names)
      {
      next if $k eq 'basename';
      my $val = $self->{att}->{$k};
      $val = '' unless defined $val;
      my $first = $val; my $not_equal = 0;
      $val .= '|';
      for my $child (@$parts)
        {
        # only consider our own autosplit parts (check should not be nec.)
#        next if !exists $child->{autosplit_basename} ||
#                        $child->{autosplit_basename} ne $basename;

        my $v = $child->{att}->{$k}; $v = '' if !defined $v;
        $not_equal ++ if $v ne $first;
        $val .= $v . '|';
        }
      # all parts equal, so do "red|red|red" => "red"
      $val = $first if $not_equal == 0;

      $val =~ s/\|+\z/\|/;				# "silver|||" => "silver|"
      $val =~ s/\|\z// if $val =~ /\|.*\|/;		# "silver|" => "silver|"
      							# but "red|blue|" => "red|blue"
      $attributes->{$k} = $val unless $val eq '|';	# skip '|'
      }
    $attributes->{basename} = $self->{att}->{basename} if defined $self->{att}->{basename};
    }

  my $new = $g->_remap_attributes( $self, $attributes, $remap, 'noquote', 'encode' );

  # For nodes, we do not output their group attribute, since they simple appear
  # at the right place in the txt:
  delete $new->{group};

  # for groups inside groups, insert their group attribute
  $new->{group} = $self->{group}->{name} 
    if $self->isa('Graph::Easy::Group') && exists $self->{group};

  if (defined $self->{origin})
    {
    $new->{origin} = $self->{origin}->{name};
    $new->{offset} = join(',', $self->offset());
    }

  # shorten output for multi-celled nodes
  # for "rows: 2;" still output "rows: 2;", because it is shorter
  if (exists $new->{columns})
    {
    $new->{size} = ($new->{columns}||1) . ',' . ($new->{rows}||1);
    delete $new->{rows};
    delete $new->{columns};
    # don't output the default size
    delete $new->{size} if $new->{size} eq '1,1';
    } 

  for my $atr (sort keys %$new)
    {
    next if $atr =~ /^border/;                  # handled special

    $att .= "$atr: $new->{$atr}; ";
    }

  if (!$self->isa_cell())
    {
    my $border;
    if (!exists $self->{autosplit})
      {
      $border = $self->border_attribute();
      }
    else
      {
      $border = Graph::Easy::_border_attribute(
	$attributes->{borderstyle}||'',
	$attributes->{borderwidth}||'',
	$attributes->{bordercolor}||'');
      }

    # XXX TODO: should do this for all attributes, not only for border
    # XXX TODO: this seems wrong anyway

    # don't include default border
    $border = '' if ref $g && $g->attribute($class,'border') eq $border;
    $att .= "border: $border; " if $border ne '';
    }

  # if we have a subclass, we probably need to include it
  my $c = '';
  $c = $1 if $class =~ /\.(\w+)/;

  # but we do not need to include it if our group has a nodeclass attribute
  $c = '' if ref($self->{group}) && $self->{group}->attribute('nodeclass') eq $c;

  # include our subclass as attribute
  $att .= "class: $c; " if $c ne '' && $c ne 'anon';

  # generate attribute text if nec.
  $att = ' { ' . $att . '}' if $att ne '';

  $att;
  }

sub _as_part_txt
  {
  # for edges, we need the name of the part of the first part, not the entire
  # autosplit text
  my $self = shift;

  my $name = $self->{name};

  # quote special chars in name
  $name =~ s/([\[\]\|\{\}\#])/\\$1/g;

  '[ ' .  $name . ' ]';
  }

sub as_pure_txt
  {
  my $self = shift;

  if (exists $self->{autosplit} && defined $self->{autosplit})
    {
    my $name = $self->{autosplit};

    # quote special chars in name (but not |)
    $name =~ s/([\[\]\{\}\#])/\\$1/g;
 
    return '[ '. $name .' ]' 
    }

  my $name = $self->{name};

  # quote special chars in name
  $name =~ s/([\[\]\|\{\}\#])/\\$1/g;

  '[ ' .  $name . ' ]';
  }

sub as_txt
  {
  my $self = shift;

  if (exists $self->{autosplit})
    {
    return '' unless defined $self->{autosplit};
    my $name = $self->{autosplit};
    # quote special chars in name (but not |)
    $name =~ s/([\[\]\{\}\#])/\\$1/g;
    return '[ ' . $name . ' ]' 
    }

  my $name = $self->{name};

  # quote special chars in name
  $name =~ s/([\[\]\|\{\}\#])/\\$1/g;

  '[ ' .  $name . ' ]' . $self->attributes_as_txt();
  }

#############################################################################

package Graph::Easy::Edge;

my $styles = {
  solid => '--',
  dotted => '..',
  double => '==',
  'double-dash' => '= ',
  dashed => '- ',
  'dot-dash' => '.-',
  'dot-dot-dash' => '..-',
  wave => '~~',
  };

sub _as_txt
  {
  my $self = shift;

  # '- Name ' or ''
  my $n = $self->{att}->{label}; $n = '' unless defined $n;

  my $left = ' '; $left = ' <' if $self->{bidirectional};
  my $right = '> '; $right = ' ' if $self->{undirected};
  
  my $s = $self->style() || 'solid';

  my $style = '--';

  # suppress border on edges
  my $suppress = { all => { label => undef } };
  if ($s =~ /^(bold|bold-dash|broad|wide|invisible)\z/)
    {
    # output "--> { style: XXX; }"
    $style = '--';
    }
  else
    {
    # output "-->" or "..>" etc
    $suppress->{all}->{style} = undef;

    $style = $styles->{ $s };
    if (!defined $style)
      {
      require Carp;
      Carp::confess ("Unknown edge style '$s'\n");
      }
    }
 
  $n = $style . " $n " if $n ne '';

  # make " -  " into " - -  "
  $style = $style . $style if $self->{undirected} && substr($style,1,1) eq ' ';

  # ' - Name -->' or ' --> ' or ' -- '
  my $a = $self->attributes_as_txt($suppress) . ' '; $a =~ s/^\s//;
  $left . $n . $style . $right . $a;
  }

1;
__END__

=head1 NAME

Graph::Easy::As_txt - Generate textual description from graph object

=head1 SYNOPSIS

	use Graph::Easy;
	
	my $graph = Graph::Easy->new();

	my $bonn = Graph::Easy::Node->new(
		name => 'Bonn',
	);
	my $berlin = Graph::Easy::Node->new(
		name => 'Berlin',
	);

	$graph->add_edge ($bonn, $berlin);

	print $graph->as_txt();

	# prints something like:

	# [ Bonn ] -> [ Berlin ]

=head1 DESCRIPTION

C<Graph::Easy::As_txt> contains just the code for converting a
L<Graph::Easy|Graph::Easy> object to a human-readable textual description.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>.

=head1 AUTHOR

Copyright (C) 2004 - 2007 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut

#############################################################################
# Output the graph as VCG or GDL text.
#
#############################################################################

package Graph::Easy::As_vcg;

$VERSION = '0.05';

#############################################################################
#############################################################################

package Graph::Easy;

use strict;

my $vcg_remap = {
  node => {
    align => \&_vcg_remap_align,
    autolabel => undef,
    autolink => undef,
    autotitle => undef,
    background => undef, 
    basename => undef,
    class => undef,
    colorscheme => undef,
    columns => undef,
    flow => undef,
    fontsize => undef,
    format => undef,
    group => undef,
    id => undef,
    link => undef,
    linkbase => undef,
    offset => undef,
    origin => undef,
    pointstyle => undef,
    rank => 'level',
    rotate => undef,
    rows => undef,
    shape => \&_vcg_remap_shape,
    size => undef,
    textstyle => undef,
    textwrap => undef,
    title => undef,
    },
  edge => {
    color => 'color',			# this entry overrides 'all'!
    align => undef,
    arrowshape => undef,
    arrowstyle => undef,
    autojoin => undef,
    autolabel => undef,
    autolink => undef,
    autosplit => undef,
    autotitle => undef,
    border => undef,
    bordercolor => undef,
    borderstyle => undef,
    borderwidth => undef,
    colorscheme => undef,
    end => undef,
    fontsize => undef,
    format => undef,
    id => undef,
    labelcolor => 'textcolor',
    link => undef,
    linkbase => undef,
    minlen => undef,
    start => undef,
    # XXX TODO: remap unknown styles
    style => 'linestyle',
    textstyle => undef,
    textwrap => undef,
    title => undef, 
    },
  graph => {
    align => \&_vcg_remap_align,
    flow => \&_vcg_remap_flow,
    label => 'title',
    type => undef,
    },
  group => {
    },
  all => {
    background => undef,
    color => 'textcolor',
    comment => undef,
    fill => 'color',
    font => 'fontname',
    },
  always => {
    },
  # this routine will handle all custom "x-dot-..." attributes
  x => \&_remap_custom_vcg_attributes,
  };

sub _remap_custom_vcg_attributes
  {
  my ($self, $name, $value) = @_;

  # drop anything that is not starting with "x-vcg-..."
  return (undef,undef) unless $name =~ /^x-vcg-/;

  $name =~ s/^x-vcg-//;			# "x-vcg-foo" => "foo"
  ($name,$value);
  }

my $vcg_shapes = {
  rect => 'box',
  diamond => 'rhomb',
  triangle => 'triangle',
  invtriangle => 'triangle',
  ellipse => 'ellipse',
  circle => 'circle',
  hexagon => 'hexagon',
  trapezium => 'trapeze',
  invtrapezium => 'uptrapeze',
  invparallelogram => 'lparallelogram',
  parallelogram => 'rparallelogram',
  };

sub _vcg_remap_shape
  {
  my ($self, $name, $shape) = @_;

  return ('invisible','yes') if $shape eq 'invisible';

  ('shape', $vcg_shapes->{$shape} || 'box');
  }

sub _vcg_remap_align
  {
  my ($self, $name, $style) = @_;

  # center => center, left => left_justify, right => right_justify
  $style .= '_justify' unless $style eq 'center';

  ('textmode', $style);
  }

my $vcg_flow = {
  'south' => 'top_to_bottom',
  'north' => 'bottom_to_top',
  'down' => 'top_to_bottom',
  'up' => 'bottom_to_top',
  'east' => 'left_to_right',
  'west' => 'right_to_left',
  'right' => 'left_to_right',
  'left' => 'right_to_left',
  };

sub _vcg_remap_flow
  {
  my ($self, $name, $style) = @_;

  ('orientation', $vcg_flow->{$style} || 'top_to_bottom');
  }

sub _class_attributes_as_vcg
  {
  # convert a hash with attribute => value mappings to a string
  my ($self, $a, $class) = @_;


  my $att = '';
  $class = '' if $class eq 'graph';
  $class .= '.' if $class ne '';
  
  # create the attributes as text:
  for my $atr (sort keys %$a)
    {
    my $v = $a->{$atr};
    $v =~ s/"/\\"/g;            # '2"' => '2\"'
    $v = '"' . $v . '"' unless $v =~ /^[0-9]+\z/;       # 1, "1a"
    $att .= "  $class$atr: $v\n";
    }
  $att =~ s/,\s$//;             # remove last ","

  $att = "\n$att" unless $att eq '';
  $att;
  }

#############################################################################

sub _generate_vcg_edge
  {
  # Given an edge, generate the VCG code for it
  my ($self, $e, $indent) = @_;

  # skip links from/to groups, these will be done later
  return '' if 
    $e->{from}->isa('Graph::Easy::Group') ||
    $e->{to}->isa('Graph::Easy::Group');

  my $edge_att = $e->attributes_as_vcg();

  $e->{_p} = undef;				# mark as processed
  "  edge:$edge_att\n";				# return edge text
  }

sub _as_vcg
  {
  my ($self) = @_;

  # convert the graph to a textual representation
  # does not need a layout() beforehand!

  # gather all edge classes to build the classname attribute from them:
  $self->{_vcg_edge_classes} = {};
  for my $e (values %{$self->{edges}})
    {
    my $class = $e->sub_class();
    $self->{_vcg_edge_classes}->{$class} = undef if defined $class && $class ne '';
    }
  # sort gathered class names and map them to integers
  my $class_names = '';
  if (keys %{$self->{_vcg_edge_classes}} > 0)
    {
    my $i = 1;
    $class_names = "\n";
    for my $ec (sort keys %{$self->{_vcg_edge_classes}})
      {
      $self->{_vcg_edge_classes}->{$ec} = $i;	# remember mapping
      $class_names .= "  classname $i: \"$ec\"\n";
      $i++;
      }
    }

  # generate the class attributes first
  my $label = $self->label();
  my $t = ''; $t = "\n  title: \"$label\"" if $label ne '';

  my $txt = "graph: {$t\n\n" .
            "  // Generated by Graph::Easy $Graph::Easy::VERSION" .
	    " at " . scalar localtime() . "\n" .
	    $class_names;

  my $groups = $self->groups();

  # to keep track of invisible helper nodes
  $self->{_vcg_invis} = {};
  # name for invisible helper nodes
  $self->{_vcg_invis_id} = 'joint0';

  my $atts = $self->{att};
  # insert the class attributes
  for my $class (qw/edge graph node/)
    {
    next if $class =~ /\./;		# skip subclasses

    my $out = $self->_remap_attributes( $class, $atts->{$class}, $vcg_remap, 'noquote');
    $txt .= $self->_class_attributes_as_vcg($out, $class);
    }

  $txt .= "\n" if $txt ne '';		# insert newline

  ###########################################################################
  # output groups as subgraphs

  # insert the edges into the proper group
  $self->_edges_into_groups() if $groups > 0;

  # output the groups (aka subclusters)
  my $indent = '    ';
  for my $group (sort { $a->{name} cmp $b->{name} } values %{$self->{groups}})
    {
    # quote special chars in group name
    my $name = $group->{name}; $name =~ s/([\[\]\(\)\{\}\#"])/\\$1/g;

#    # output group attributes first
#    $txt .= "  subgraph \"cluster$group->{id}\" {\n${indent}label=\"$name\";\n";
   
    # Make a copy of the attributes, including our class attributes:
    my $copy = {};
    my $attribs = $group->get_attributes();

    for my $a (keys %$attribs)
      {
      $copy->{$a} = $attribs->{$a};
      }
#    # set some defaults
#    $copy->{'borderstyle'} = 'solid' unless defined $copy->{'borderstyle'};

    my $out = {};
#    my $out = $self->_remap_attributes( $group->class(), $copy, $vcg_remap, 'noquote');

    # Set some defaults:
    $out->{fillcolor} = '#a0d0ff' unless defined $out->{fillcolor};
#    $out->{labeljust} = 'l' unless defined $out->{labeljust};

    my $att = '';
    # we need to output style first ("filled" and "color" need come later)
    for my $atr (reverse sort keys %$out)
      {
      my $v = $out->{$atr};
      $v = '"' . $v . '"';
      $att .= "    $atr: $v\n";
      }
    $txt .= $att . "\n" if $att ne '';
 
#    # output nodes (w/ or w/o attributes) in that group
#    for my $n ($group->sorted_nodes())
#      {
#      my $att = $n->attributes_as_vcg();
#      $n->{_p} = undef;			# mark as processed
#      $txt .= $indent . $n->as_graphviz_txt() . $att . "\n";
#      }

#    # output node connections in this group
#    for my $e (values %{$group->{edges}})
#      {
#      next if exists $e->{_p};
#      $txt .= $self->_generate_edge($e, $indent);
#      }

    $txt .= "  }\n";
    }

  my $root = $self->attribute('root');
  $root = '' unless defined $root;

  my $count = 0;
  # output nodes with attributes first, sorted by their name
  for my $n (sort { $a->{name} cmp $b->{name} } values %{$self->{nodes}})
    {
    next if exists $n->{_p};
    my $att = $n->attributes_as_vcg($root);
    if ($att ne '')
      {
      $n->{_p} = undef;			# mark as processed
      $count++;
      $txt .= "  node:" . $att . "\n"; 
      }
    }
 
  $txt .= "\n" if $count > 0;		# insert a newline

  my @nodes = $self->sorted_nodes();

  foreach my $n (@nodes)
    {
    my @out = $n->successors();
    my $first = $n->as_vcg_txt();
    if ((@out == 0) && ( (scalar $n->predecessors() || 0) == 0))
      {
      # single node without any connections (unless already output)
      $txt .= "  node: { title: " . $first . " }\n" unless exists $n->{_p};
      }
    # for all outgoing connections
    foreach my $other (reverse @out)
      {
      # in case there is more than one edge going from N to O
      my @edges = $n->edges_to($other);
      foreach my $e (@edges)
        {
        next if exists $e->{_p};
        $txt .= $self->_generate_vcg_edge($e, '  ');
        }
      }
    }

  # insert now edges between groups (clusters/subgraphs)

#  foreach my $e (values %{$self->{edges}})
#    {
#    $txt .= $self->_generate_group_edge($e, '  ') 
#     if $e->{from}->isa('Graph::Easy::Group') ||
#        $e->{to}->isa('Graph::Easy::Group');
#    }

  # clean up
  for my $n ( values %{$self->{nodes}}, values %{$self->{edges}})
    {
    delete $n->{_p};
    }
  delete $self->{_vcg_invis};		# invisible helper nodes for joints
  delete $self->{_vcg_invis_id};	# invisible helper node name
  delete $self->{_vcg_edge_classes};

  $txt .  "\n}\n";			# close the graph
  }

package Graph::Easy::Node;

sub attributes_as_vcg
  {
  # return the attributes of this node as text description
  my ($self, $root) = @_;
  $root = '' unless defined $root;

  my $att = '';
  my $class = $self->class();

  return '' unless ref $self->{graph};

  my $g = $self->{graph};

  # get all attributes, excluding the class attributes
  my $a = $self->raw_attributes();

  # add the attributes that are listed under "always":
  my $attr = $self->{att};
  my $base_class = $class; $base_class =~ s/\..*//;
  my $list = $vcg_remap->{always}->{$class} || $vcg_remap->{always}->{$base_class};

  for my $name (@$list)
    {
    # for speed, try to look it up directly

    # look if we have a code ref, if yes, simple set the value to undef
    # and let the coderef handle it later:
    if ( ref($vcg_remap->{$base_class}->{$name}) ||
         ref($vcg_remap->{all}->{$name}) )
      {
      $a->{$name} = $attr->{$name};
      }
    else
      {
      $a->{$name} = $attr->{$name};
      $a->{$name} = $self->attribute($name) unless defined $a->{$name} && $a->{$name} ne 'inherit';
      }
    }

  $a = $g->_remap_attributes( $self, $a, $vcg_remap, 'noquote');

  if ($self->isa('Graph::Easy::Edge'))
    {
    $a->{sourcename} = $self->{from}->{name};
    $a->{targetname} = $self->{to}->{name};
    my $class = $self->sub_class();
    $a->{class} = $self->{graph}->{_vcg_edge_classes}->{ $class } if defined $class && $class ne '';
    }
  else
    {
    # title: "Bonn"
    $a->{title} = $self->{name};
    }

  # do not needlessly output labels:
  delete $a->{label} if !$self->isa('Graph::Easy::Edge') &&		# not an edge
	exists $a->{label} && $a->{label} eq $self->{name};

  # bidirectional and undirected edges
  if ($self->{bidirectional})
    {
    delete $a->{dir};
    my ($n,$s) = Graph::Easy::_graphviz_remap_arrow_style(
	$self,'', $self->attribute('arrowstyle'));
    $a->{arrowhead} = $s; 
    $a->{arrowtail} = $s; 
    }
  if ($self->{undirected})
    {
    delete $a->{dir};
    $a->{arrowhead} = 'none'; 
    $a->{arrowtail} = 'none'; 
    }

  # borderstyle: double:
  if (!$self->isa('Graph::Easy::Edge'))
    {
    my $style = $self->attribute('borderstyle');
    $a->{peripheries} = 2 if $style =~ /^double/;
    }

  # For nodes with shape plaintext, set the fillcolor to the background of
  # the graph/group
  my $shape = $a->{shape} || 'rect';
  if ($class =~ /node/ && $shape eq 'plaintext')
    {
    my $p = $self->parent();
    $a->{fillcolor} = $p->attribute('fill');
    $a->{fillcolor} = 'white' if $a->{fillcolor} eq 'inherit';
    }

  $shape = $self->attribute('shape') unless $self->isa_cell();

  # for point-shaped nodes, include the point as label and set width/height
  if ($shape eq 'point')
    {
    require Graph::Easy::As_ascii;		# for _u8 and point-style

    my $style = $self->_point_style( $self->attribute('pointstyle') );

    $a->{label} = $style;
    # for point-shaped invisible nodes, set height/width = 0
    $a->{width} = 0, $a->{height} = 0 if $style eq '';  
    }
  if ($shape eq 'invisible')
    {
    $a->{label} = ' ';
    }

  $a->{rank} = '0' if $root ne '' && $root eq $self->{name};

  # create the attributes as text:
  for my $atr (sort keys %$a)
    {
    my $v = $a->{$atr};
    $v =~ s/"/\\"/g;		# '2"' => '2\"'
    $v = '"' . $v . '"' unless $v =~ /^[0-9]+\z/;	# 1, "1a"
    $att .= "$atr: $v ";
    }
  $att =~ s/,\s$//;             # remove last ","

  # generate attribute text if nec.
  $att = ' { ' . $att . '}' if $att ne '';

  $att;
  }

sub as_vcg_txt
  {
  # return the node itself (w/o attributes) as VCG representation
  my $self = shift;

  my $name = $self->{name};

  # escape special chars in name (including doublequote!)
  $name =~ s/([\[\]\(\)\{\}"])/\\$1/g;

  # quote:
  '"' . $name . '"';
  }
 
1;
__END__

=head1 NAME

Graph::Easy::As_vcg - Generate VCG/GDL text from Graph::Easy object

=head1 SYNOPSIS

	use Graph::Easy;
	
	my $graph = Graph::Easy->new();

	my $bonn = Graph::Easy::Node->new(
		name => 'Bonn',
	);
	my $berlin = Graph::Easy::Node->new(
		name => 'Berlin',
	);

	$graph->add_edge ($bonn, $berlin);

	print $graph->as_vcg();


This prints something like this:

	graph: {
		node: { title: "Bonn" }
		node: { title: "Berlin" }
		edge: { sourcename: "Bonn" targetname: "Berlin" }
	}

=head1 DESCRIPTION

C<Graph::Easy::As_vcg> contains just the code for converting a
L<Graph::Easy|Graph::Easy> object to either a VCG 
or GDL textual description.

Note that the generated format is compatible to C<GDL> aka I<Graph
Description Language>.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph::Easy>, L<http://rw4.cs.uni-sb.de/~sander/html/gsvcg1.html>.

=head1 AUTHOR

Copyright (C) 2004-2008 by Tels L<http://bloodgate.com>

See the LICENSE file for information.

=cut
############################################################################
# Manage, and layout graphs on a flat plane.
#
#############################################################################

package Graph::Easy;

use 5.008002;
use Graph::Easy::Base;
use Graph::Easy::Attributes;
use Graph::Easy::Edge;
use Graph::Easy::Group;
use Graph::Easy::Group::Anon;
use Graph::Easy::Layout;
use Graph::Easy::Node;
use Graph::Easy::Node::Anon;
use Graph::Easy::Node::Empty;
use Scalar::Util qw/weaken/;

$VERSION = '0.69';
@ISA = qw/Graph::Easy::Base/;

use strict;
my $att_aliases;

BEGIN 
  {
  # a few aliases for backwards compatibility
  *get_attribute = \&attribute; 
  *as_html_page = \&as_html_file;
  *as_graphviz_file = \&as_graphviz;
  *as_ascii_file = \&as_ascii;
  *as_boxart_file = \&as_boxart;
  *as_txt_file = \&as_txt;
  *as_vcg_file = \&as_vcg;
  *as_gdl_file = \&as_gdl;
  *as_graphml_file = \&as_graphml;

  # a few aliases for code re-use
  *_aligned_label = \&Graph::Easy::Node::_aligned_label;
  *quoted_comment = \&Graph::Easy::Node::quoted_comment;
  *_un_escape = \&Graph::Easy::Node::_un_escape;
  *_convert_pod = \&Graph::Easy::Node::_convert_pod;
  *_label_as_html = \&Graph::Easy::Node::_label_as_html;
  *_wrapped_label = \&Graph::Easy::Node::_wrapped_label;
  *get_color_attribute = \&color_attribute;
  *get_custom_attributes = \&Graph::Easy::Node::get_custom_attributes;
  *custom_attributes = \&Graph::Easy::Node::get_custom_attributes;
  $att_aliases = Graph::Easy::_att_aliases();

  # backwards compatibility
  *is_simple_graph = \&is_simple;

  # compatibility to Graph
  *vertices = \&nodes;
  }

#############################################################################

sub new
  {
  # override new() as to not set the {id}
  my $class = shift;

  # called like "new->('[A]->[B]')":
  if (@_ == 1 && !ref($_[0]))
    {
    require Graph::Easy::Parser;
    my $parser = Graph::Easy::Parser->new();
    my $self = eval { $parser->from_text($_[0]); };
    if (!defined $self)
      {
      $self = Graph::Easy->new( fatal_errors => 0 );
      $self->error( 'Error: ' . $parser->error() ||
        'Unknown error while parsing initial text' );
      $self->catch_errors( 0 );
      }
    return $self;
    }

  my $self = bless {}, $class;

  my $args = $_[0];
  $args = { @_ } if ref($args) ne 'HASH';

  $self->_init($args);
  }

sub DESTROY
  {
  my $self = shift;
 
  # Be carefull to not delete ->{graph}, these will be cleaned out by
  # Perl automatically in O(1) time, manual delete is O(N) instead.

  delete $self->{chains};
  # clean out pointers in child-objects so that they can safely be reused
  for my $n (values %{$self->{nodes}})
    {
    if (ref($n))
      {
      delete $n->{edges};
      delete $n->{group};
      }
    }
  for my $e (values %{$self->{edges}})
    {
    if (ref($e))
      {
      delete $e->{cells};
      delete $e->{to};
      delete $e->{from};
      }
    }
  for my $g (values %{$self->{groups}})
    {
    if (ref($g))
      {
      delete $g->{nodes};
      delete $g->{edges};
      }
    }
  }

# Attribute overlay for HTML output:

my $html_att = {
  node => {
    borderstyle => 'solid',
    borderwidth => '1px',
    bordercolor => '#000000',
    align => 'center',
    padding => '0.2em',
    'padding-left' => '0.3em',
    'padding-right' => '0.3em',
    margin => '0.1em',
    fill => 'white',
    },
  'node.anon' => {
    'borderstyle' => 'none',
    # ' inherit' to protect the value from being replaced by the one from "node"
    'background' => ' inherit',
    },
  graph => {
    margin => '0.5em',
    padding => '0.5em',
    'empty-cells' => 'show',
    },
  edge => { 
    border => 'none',
    padding => '0.2em',
    margin => '0.1em',
    'font' => 'monospaced, courier-new, courier, sans-serif',
    'vertical-align' => 'bottom',
    },
  group => { 
    'borderstyle' => 'dashed',
    'borderwidth' => '1',
    'fontsize' => '0.8em',
    fill => '#a0d0ff',
    padding => '0.2em',
# XXX TODO:
# in HTML, align left is default, so we could omit this:
    align => 'left',
    },
  'group.anon' => {
    'borderstyle' => 'none',
    background => 'white',
    },
  };


sub _init
  {
  my ($self,$args) = @_;

  $self->{debug} = 0;
  $self->{timeout} = 5;			# in seconds
  $self->{strict} = 1;			# check attributes strict?
  
  $self->{class} = 'graph';
  $self->{id} = '';
  $self->{groups} = {};

  # node objects, indexed by their unique name
  $self->{nodes} = {};
  # edge objects, indexed by unique ID
  $self->{edges} = {};

  $self->{output_format} = 'html';

  $self->{_astar_bias} = 0.001;

  # default classes to use in add_foo() methods
  $self->{use_class} = {
    edge => 'Graph::Easy::Edge',
    group => 'Graph::Easy::Group',
    node => 'Graph::Easy::Node',
  };

  # Graph::Easy will die, Graph::Easy::Parser::Graphviz will warn
  $self->{_warn_on_unknown_attributes} = 0;
  $self->{fatal_errors} = 1;

  # The attributes of the graph itself, _and_ the class/subclass attributes.
  # These can share a hash, because:
  # *  {att}->{graph} contains both the graph attributes and the class, since
  #    these are synonymous, it is not possible to have more than one graph.
  # *  'node', 'group', 'edge' are not valid attributes for a graph, so
  #    setting "graph { node: 1; }" is not possible and can thus not overwrite
  #    the entries from att->{node}.
  # *  likewise for "node.subclass", attribute names never have a "." in them
  $self->{att} = {};

  foreach my $k (keys %$args)
    {
    if ($k !~ /^(timeout|debug|strict|fatal_errors|undirected)\z/)
      {
      $self->error ("Unknown option '$k'");
      }
    if ($k eq 'undirected' && $args->{$k})
      {
      $self->set_attribute('type', 'undirected'); next;
      }
    $self->{$k} = $args->{$k};
    }

  binmode(STDERR,'utf8') or die ("Cannot do binmode(STDERR,'utf8'")
    if $self->{debug};

  $self->{score} = undef;

  $self->randomize();

  $self;
  }

#############################################################################
# accessors

sub timeout
  {
  my $self = shift;

  $self->{timeout} = $_[0] if @_;
  $self->{timeout};
  }

sub debug
  {
  my $self = shift;

  $self->{debug} = $_[0] if @_;
  $self->{debug};
  }

sub strict
  {
  my $self = shift;

  $self->{strict} = $_[0] if @_;
  $self->{strict};
  }

sub type
  {
  # return the type of the graph, "undirected" or "directed"
  my $self = shift;

  $self->{att}->{type} || 'directed';
  }

sub is_simple
  {
  # return true if the graph does not have multiedges
  my $self = shift;

  my %count;
  for my $e (values %{$self->{edges}})
    {
    my $id = "$e->{to}->{id},$e->{from}->{id}";
    return 0 if exists $count{$id};
    $count{$id} = undef;
    }

  1;					# found none
  }

sub is_directed
  {
  # return true if the graph is directed
  my $self = shift;

  $self->attribute('type') eq 'directed' ? 1 : 0;
  }

sub is_undirected
  {
  # return true if the graph is undirected
  my $self = shift;

  $self->attribute('type') eq 'undirected' ? 1 : 0;
  }

sub id
  {
  my $self = shift;

  $self->{id} = shift if defined $_[0];
  $self->{id};
  }

sub score
  {
  my $self = shift;

  $self->{score};
  }

sub randomize
  {
  my $self = shift;

  srand();
  $self->{seed} = rand(2 ** 31);

  $self->{seed};
  }

sub root_node
  {
  # Return the root node
  my $self = shift;
  
  my $root = $self->{att}->{root};
  $root = $self->{nodes}->{$root} if defined $root;

  $root;
  }

sub source_nodes
  {
  # return nodes with only outgoing edges
  my $self = shift;

  my @roots;
  for my $node (values %{$self->{nodes}})
    {
    push @roots, $node 
      if (keys %{$node->{edges}} != 0) && !$node->has_predecessors();
    }
  @roots;
  }

sub predecessorless_nodes
  {
  # return nodes with no incoming (but maybe outgoing) edges
  my $self = shift;

  my @roots;
  for my $node (values %{$self->{nodes}})
    {
    push @roots, $node 
      if (keys %{$node->{edges}} == 0) || !$node->has_predecessors();
    }
  @roots;
  }

sub label
  {
  my $self = shift;

  my $label = $self->{att}->{graph}->{label}; $label = '' unless defined $label;
  $label = $self->_un_escape($label) if !$_[0] && $label =~ /\\[EGHNT]/;
  $label;
  }

sub link
  {
  # return the link, build from linkbase and link (or autolink)
  my $self = shift;

  my $link = $self->attribute('link');
  my $autolink = ''; $autolink = $self->attribute('autolink') if $link eq '';
  if ($link eq '' && $autolink ne '')
    {
    $link = $self->{name} if $autolink eq 'name';
    # defined to avoid overriding "name" with the non-existant label attribute
    $link = $self->{att}->{label} if $autolink eq 'label' && defined $self->{att}->{label};
    $link = $self->{name} if $autolink eq 'label' && !defined $self->{att}->{label};
    }
  $link = '' unless defined $link;

  # prepend base only if link is relative
  if ($link ne '' && $link !~ /^([\w]{3,4}:\/\/|\/)/)
    {
    $link = $self->attribute('linkbase') . $link;
    }

  $link = $self->_un_escape($link) if !$_[0] && $link =~ /\\[EGHNT]/;

  $link;
  }

sub parent
  {
  # return parent object, for graphs that is undef
  undef;
  }

sub seed
  {
  my $self = shift;

  $self->{seed} = $_[0] if @_ > 0;

  $self->{seed};
  }

sub nodes
  {
  # return all nodes as objects, in scalar context their count
  my ($self) = @_;

  my $n = $self->{nodes};

  return scalar keys %$n unless wantarray;	# shortcut

  values %$n;
  }

sub anon_nodes
  {
  # return all anon nodes as objects
  my ($self) = @_;

  my $n = $self->{nodes};

  if (!wantarray)
    {
    my $count = 0;
    for my $node (values %$n)
      {
      $count++ if $node->is_anon();
      }
    return $count;
    }

  my @anon = ();
  for my $node (values %$n)
    {
    push @anon, $node if $node->is_anon();
    }
  @anon;
  }

sub edges
  {
  # Return all the edges this graph contains as objects
  my ($self) = @_;

  my $e = $self->{edges};

  return scalar keys %$e unless wantarray;	# shortcut

  values %$e;
  }

sub edges_within
  {
  # return all the edges as objects
  my ($self) = @_;

  my $e = $self->{edges};

  return scalar keys %$e unless wantarray;	# shortcut

  values %$e;
  }

sub sorted_nodes
  {
  # return all nodes as objects, sorted by $f1 or $f1 and $f2
  my ($self, $f1, $f2) = @_;

  return scalar keys %{$self->{nodes}} unless wantarray;	# shortcut

  $f1 = 'id' unless defined $f1;
  # sorting on a non-unique field alone will result in unpredictable
  # sorting order due to hashing
  $f2 = 'name' if !defined $f2 && $f1 !~ /^(name|id)$/;

  my $sort;
  $sort = sub { $a->{$f1} <=> $b->{$f1} } if $f1;
  $sort = sub { abs($a->{$f1}) <=> abs($b->{$f1}) } if $f1 && $f1 eq 'rank';
  $sort = sub { $a->{$f1} cmp $b->{$f1} } if $f1 && $f1 =~ /^(name|title|label)$/;
  $sort = sub { $a->{$f1} <=> $b->{$f1} || $a->{$f2} <=> $b->{$f2} } if $f2;
  $sort = sub { abs($a->{$f1}) <=> abs($b->{$f1}) || $a->{$f2} <=> $b->{$f2} } if $f2 && $f1 eq 'rank';
  $sort = sub { $a->{$f1} <=> $b->{$f1} || abs($a->{$f2}) <=> abs($b->{$f2}) } if $f2 && $f2 eq 'rank';
  $sort = sub { $a->{$f1} <=> $b->{$f1} || $a->{$f2} cmp $b->{$f2} } if $f2 &&
           $f2 =~ /^(name|title|label)$/;
  $sort = sub { abs($a->{$f1}) <=> abs($b->{$f1}) || $a->{$f2} cmp $b->{$f2} } if 
           $f1 && $f1 eq 'rank' &&
           $f2 && $f2 =~ /^(name|title|label)$/;
  # 'name', 'id'
  $sort = sub { $a->{$f1} cmp $b->{$f1} || $a->{$f2} <=> $b->{$f2} } if $f2 &&
           $f2 eq 'id' && $f1 ne 'rank';

  # the 'return' here should not be removed
  return sort $sort values %{$self->{nodes}};
  }

sub add_edge_once
  {
  # add an edge, unless it already exists. In that case it returns undef
  my ($self, $x, $y, $edge) = @_;

  # got an edge object? Don't add it twice!
  return undef if ref($edge);

  # turn plaintext scalars into objects 
  my $x1 = $self->{nodes}->{$x} unless ref $x;
  my $y1 = $self->{nodes}->{$y} unless ref $y;

  # nodes do exist => maybe the edge also exists
  if (ref($x1) && ref($y1))
    {
    my @ids = $x1->edges_to($y1);

    return undef if @ids;	# found already one edge?
    }

  $self->add_edge($x,$y,$edge);
  }

sub edge
  {
  # return an edge between two nodes as object
  my ($self, $x, $y) = @_;

  # turn plaintext scalars into objects 
  $x = $self->{nodes}->{$x} unless ref $x;
  $y = $self->{nodes}->{$y} unless ref $y;

  # node does not exist => edge does not exist
  return undef unless ref($x) && ref($y);

  my @ids = $x->edges_to($y);
  
  wantarray ? @ids : $ids[0];
  }

sub flip_edges
  {
  # turn all edges going from $x to $y around
  my ($self, $x, $y) = @_;

  # turn plaintext scalars into objects 
  $x = $self->{nodes}->{$x} unless ref $x;
  $y = $self->{nodes}->{$y} unless ref $y;

  # node does not exist => edge does not exist
  # if $x == $y, return early (no need to turn selfloops)

  return $self unless ref($x) && ref($y) && ($x != $y);

  for my $e (values %{$x->{edges}})
    {
    $e->flip() if $e->{from} == $x && $e->{to} == $y;
    }

  $self;
  }

sub node
  {
  # return node by name
  my ($self,$name) = @_;
  $name = '' unless defined $name;

  $self->{nodes}->{$name};
  }

sub rename_node
  {
  # change the name of a node
  my ($self, $node, $new_name) = @_;

  $node = $self->{nodes}->{$node} unless ref($node);

  if (!ref($node))
    {
    $node = $self->add_node($new_name);
    }
  else
    {
    if (!ref($node->{graph}))
      {
      # add node to ourself
      $node->{name} = $new_name;
      $self->add_node($node);
      }
    else
      {
      if ($node->{graph} != $self)
        {
	$node->{graph}->del_node($node);
	$node->{name} = $new_name;
	$self->add_node($node);
	}
      else
	{
	delete $self->{nodes}->{$node->{name}};
	$node->{name} = $new_name;
	$self->{nodes}->{$node->{name}} = $node;
	}
      }
    }
  if ($node->is_anon())
    {
    # turn anon nodes into a normal node (since it got a new name):
    bless $node, $self->{use_class}->{node} || 'Graph::Easy::Node';
    delete $node->{att}->{label} if $node->{att}->{label} eq ' ';
    $node->{class} = 'group';
    }
  $node;
  }

sub rename_group
  {
  # change the name of a group
  my ($self, $group, $new_name) = @_;

  if (!ref($group))
    {
    $group = $self->add_group($new_name);
    }
  else
    {
    if (!ref($group->{graph}))
      {
      # add node to ourself
      $group->{name} = $new_name;
      $self->add_group($group);
      }
    else
      {
      if ($group->{graph} != $self)
        {
	$group->{graph}->del_group($group);
	$group->{name} = $new_name;
	$self->add_group($group);
	}
      else
	{
	delete $self->{groups}->{$group->{name}};
	$group->{name} = $new_name;
	$self->{groups}->{$group->{name}} = $group;
	}
      }
    }
  if ($group->is_anon())
    {
    # turn anon groups into a normal group (since it got a new name):
    bless $group, $self->{use_class}->{group} || 'Graph::Easy::Group';
    delete $group->{att}->{label} if $group->{att}->{label} eq '';
    $group->{class} = 'group';
    }
  $group;
  }

#############################################################################
# attribute handling

sub _check_class
  {
  # Check the given class ("graph", "node.foo" etc.) or class selector
  # (".foo") for being valid, and return a list of base classes this applies
  # to. Handles also a list of class selectors like ".foo, .bar, node.foo".
  my ($self, $selector) = @_;

  my @parts = split /\s*,\s*/, $selector;

  my @classes = ();
  for my $class (@parts)
    {
    # allowed classes, subclasses (except "graph."), selectors (excpet ".")
    return unless $class =~ /^(\.\w|node|group|edge|graph\z)/;
    # "node." is invalid, too
    return if $class =~ /\.\z/;

    # run a loop over all classes: "node.foo" => ("node"), ".foo" => ("node","edge","group")
    $class =~ /^(\w*)/; 
    my $base_class = $1; 
    if ($base_class eq '')
      {
      push @classes, ('edge'.$class, 'group'.$class, 'node'.$class);
      }
    else
      {
      push @classes, $class;
      }
    } # end for all parts

  @classes;
  }

sub set_attribute
  {
  my ($self, $class_selector, $name, $val) = @_;

  # allow calling in the style of $graph->set_attribute($name,$val);
  if (@_ == 3)
    {
    $val = $name;
    $name = $class_selector;
    $class_selector = 'graph';
    }

  # font-size => fontsize
  $name = $att_aliases->{$name} if exists $att_aliases->{$name};

  $name = 'undef' unless defined $name;
  $val = 'undef' unless defined $val;

  my @classes = $self->_check_class($class_selector);

  return $self->error ("Illegal class '$class_selector' when trying to set attribute '$name' to '$val'")
    if @classes == 0;

  for my $class (@classes)
    {
    $val = $self->unquote_attribute($class,$name,$val);

    if ($self->{strict})
      {
      my ($rc, $newname, $v) = $self->validate_attribute($name,$val,$class);
      return if defined $rc;		# error?

      $val = $v;
      }

    $self->{score} = undef;	# invalidate layout to force a new layout
    delete $self->{cache};	# setting a class or flow must invalidate the cache

    # handle special attribute 'gid' like in "graph { gid: 123; }"
    if ($class eq 'graph')
      {
      if ($name =~ /^g?id\z/)
        {
        $self->{id} = $val;
        }
      # handle special attribute 'output' like in "graph { output: ascii; }"
      if ($name eq 'output')
        {
        $self->{output_format} = $val;
        }
      }

    my $att = $self->{att};
    # create hash if it doesn't exist yet
    $att->{$class} = {} unless ref $att->{$class};

    if ($name eq 'border')
      {
      my $c = $att->{$class};

      ($c->{borderstyle}, $c->{borderwidth}, $c->{bordercolor}) =
	 $self->split_border_attributes( $val );

      return $val;
      }

    $att->{$class}->{$name} = $val;

    } # end for all selected classes

  $val;
  }

sub set_attributes
  {
  my ($self, $class_selector, $att) = @_;

  # if called as $graph->set_attributes( { color => blue } ), assume
  # class eq 'graph'

  if (defined $class_selector && !defined $att)
    {
    $att = $class_selector; $class_selector = 'graph';
    }

  my @classes = $self->_check_class($class_selector);

  return $self->error ("Illegal class '$class_selector' when trying to set attributes")
    if @classes == 0;

  foreach my $a (keys %$att)
    {
    for my $class (@classes)
      {
      $self->set_attribute($class, $a, $att->{$a});
      }
    } 
  $self;
  }

sub del_attribute
  {
  # delete the attribute with the name in the selected class(es)
  my ($self, $class_selector, $name) = @_;

  if (@_ == 2)
    {
    $name = $class_selector; $class_selector = 'graph';
    }

  # font-size => fontsize
  $name = $att_aliases->{$name} if exists $att_aliases->{$name};

  my @classes = $self->_check_class($class_selector);

  return $self->error ("Illegal class '$class_selector' when trying to delete attribute '$name'")
    if @classes == 0;

  for my $class (@classes)
    {
    my $a = $self->{att}->{$class};

    delete $a->{$name};
    if ($name eq 'size')
      {
      delete $a->{rows};
      delete $a->{columns};
      }
    if ($name eq 'border')
      {
      delete $a->{borderstyle};
      delete $a->{borderwidth};
      delete $a->{bordercolor};
      }
    }
  $self;
  }

#############################################################################

# for determining the absolute graph flow
my $p_flow =
  {
  'east' => 90,
  'west' => 270,
  'north' => 0,
  'south' => 180,
  'up' => 0,
  'down' => 180,
  'back' => 270,
  'left' => 270,
  'right' => 90,
  'front' => 90,
  'forward' => 90,
  };

sub flow
  {
  # return out flow as number
  my ($self)  = @_;

  my $flow = $self->{att}->{graph}->{flow};

  return 90 unless defined $flow;

  my $f = $p_flow->{$flow}; $f = $flow unless defined $f;
  $f;
  }

#############################################################################
#############################################################################
# Output (as_ascii, as_html) routines; as_txt() is in As_txt.pm, as_graphml
# is in As_graphml.pm

sub output_format
  {
  # set the output format
  my $self = shift;

  $self->{output_format} = shift if $_[0];
  $self->{output_format};
  }

sub output
  {
  # general output routine, to output the graph as the format that was
  # specified in the graph source itself
  my $self = shift;

  no strict 'refs';

  my $method = 'as_' . $self->{output_format};

  $self->_croak("Cannot find a method to generate '$self->{output_format}'")
    unless $self->can($method);

  $self->$method();
  }

sub _class_styles
  {
  # Create the style sheet with the class lists. This is used by both
  # css() and as_svg(). $skip is a qr// object that returns true for
  # attribute names to be skipped (e.g. excluded), and $map is a
  # HASH that contains mapping for attribute names for the output.
  # "$base" is the basename for classes (either "table.graph$id" if 
  # not defined, or whatever you pass in, like "" for svg).
  # $indent is a left-indenting spacer like "  ".
  # $overlay contains a HASH with attribute-value pairs to set as defaults.

  my ($self, $skip, $map, $base, $indent, $overlay) = @_;

  my $a = $self->{att};

  $indent = '' unless defined $indent;
  my $indent2 = $indent x 2; $indent2 = '  ' if $indent2 eq '';

  my $class_list = { edge => {}, node => {}, group => {} };
  if (defined $overlay)
    {
    $a = {};

    # make a copy from $self->{att} to $a:

    for my $class (keys %{$self->{att}})
      {
      my $ac = $self->{att}->{$class};
      $a->{$class} = {};
      my $acc = $a->{$class};
      for my $k (keys %$ac)
        {
        $acc->{$k} = $ac->{$k};
        }
      }

    # add the extra keys
    for my $class (keys %$overlay)
      {
      my $oc = $overlay->{$class};
      # create the hash if it doesn't exist yet
      $a->{$class} = {} unless ref $a->{$class};
      my $acc = $a->{$class};
      for my $k (keys %$oc)
        {
        $acc->{$k} = $oc->{$k} unless exists $acc->{$k};
        }
      $class_list->{$class} = {};
      }
    }

  my $id = $self->{id};

  my @primaries = sort keys %$class_list;
  foreach my $primary (@primaries)
    {
    my $cl = $class_list->{$primary};			# shortcut
    foreach my $class (sort keys %$a)
      {
      if ($class =~ /^$primary\.(.*)/)
        {
        $cl->{$1} = undef;				# note w/o doubles
        }
      }
    }

  $base = "table.graph$id " unless defined $base;

  my $groups = $self->groups();				# do we have groups?

  my $css = '';
  foreach my $class (sort keys %$a)
    {
    next if keys %{$a->{$class}} == 0;			# skip empty ones

    my $c = $class; $c =~ s/\./_/g;			# node.city => node_city

    next if $class eq 'group' and $groups == 0;

    my $css_txt = '';
    my $cls = '';
    if ($class eq 'graph' && $base eq '')
      {
      $css_txt .= "${indent}.$class \{\n";			# for SVG
      }
    elsif ($class eq 'graph')
      {
      $css_txt .= "$indent$base\{\n";
      }
    else
      {
      if ($c !~ /\./)					# one of our primary ones
        {
        # generate also class list 			# like: "cities,node_rivers"
        $cls = join (",$base.${c}_", sort keys %{ $class_list->{$c} });
        $cls = ",$base.${c}_$cls" if $cls ne '';		# like: ",node_cities,node_rivers"
        }
      $css_txt .= "$indent$base.$c$cls {\n";
      }
    my $done = 0;
    foreach my $att (sort keys %{$a->{$class}})
      {
      # should be skipped?
      next if $att =~ $skip || $att eq 'border';

      # do not specify attributes for the entire graph (only for the label)
      # $base ne '' skips this rule for SVG output
      next if $class eq 'graph' && $base ne '' && $att =~ /^(color|font|fontsize|align|fill)\z/;

      $done++;						# how many did we really?
      my $val = $a->{$class}->{$att};

      next if !defined $val;

      # for groups, set to none, it will be later overriden for the different
      # cells (like "ga") with a border only on the appropriate side:
      $val = 'none' if $att eq 'borderstyle' && $class eq 'group';
      # fix border-widths to be in pixel
      $val .= 'px' if $att eq 'borderwidth' && $val !~ /(px|em|%)\z/;

      # for color attributes, convert to hex
      my $entry = $self->_attribute_entry($class, $att);

      if (defined $entry)
	{
	my $type = $entry->[ ATTR_TYPE_SLOT ] || ATTR_STRING;
	if ($type == ATTR_COLOR)
	  {
	  # create as RGB color
	  $val = $self->get_color_attribute($class,$att) || $val;
	  }
	}
      # change attribute name/value?
      if (exists $map->{$att})
	{
        $att = $map->{$att} unless ref $map->{$att};		# change attribute name?
        ($att,$val) = &{$map->{$att}}($self,$att,$val,$class) if ref $map->{$att};
	}

      # value is "inherit"?
      if ($class ne 'graph' && $att && $val && $val eq 'inherit')
        {
        # get the value from one class "up"

	# node.foo => node, node => graph
        my $base_class = $class; $base_class = 'graph' unless $base_class =~ /\./;
	$base_class =~ s/\..*//;

        $val = $a->{$base_class}->{$att};

	if ($base_class ne 'graph' && (!defined $val || $val eq 'inherit'))
	  {
	  # node.foo => node, inherit => graph
          $val = $a->{graph}->{$att};
	  $att = undef if !defined $val;
	  }
	}

      $css_txt .= "$indent2$att: $val;\n" if defined $att && defined $val;
      }

    $css_txt .= "$indent}\n";
    $css .= $css_txt if $done > 0;			# skip if no attributes at all
    }
  $css;
  }

sub _skip
  {
  # return a regexp that specifies which attributes to suppress in CSS
  my ($self) = shift;

  # skip these for CSS
  qr/^(basename|columns|colorscheme|comment|class|flow|format|group|rows|root|size|offset|origin|linkbase|(auto)?(label|link|title)|auto(join|split)|(node|edge)class|shape|arrowstyle|label(color|pos)|point(style|shape)|textstyle|style)\z/;
  }

#############################################################################
# These routines are used by as_html for the generation of CSS

sub _remap_text_wrap
  {
  my ($self,$name,$style) = @_;

  return (undef,undef) if $style ne 'auto';

  # make text wrap again
  ('white-space','normal');
  }

sub _remap_fill
  {
  my ($self,$name,$color,$class) = @_;

  return ('background',$color) unless $class =~ /edge/;

  # for edges, the fill is ignored
  (undef,undef);
  }

#############################################################################

sub css
  {
  my $self = shift;

  my $a = $self->{att};
  my $id = $self->{id};

  # for each primary class (node/group/edge) we need to find all subclasses,
  # and list them in the CSS, too. Otherwise "node_city" would not inherit
  # the attributes from "node".

  my $css = $self->_class_styles( $self->_skip(),
    {
      fill => \&_remap_fill,
      textwrap => \&_remap_text_wrap,
      align => 'text-align',
      font => 'font-family',
      fontsize => 'font-size',
      bordercolor => 'border-color',
      borderstyle => 'border-style',
      borderwidth => 'border-width',
    },
    undef,
    undef, 
    $html_att,
    );

  my @groups = $self->groups();

  # Set attributes for all TDs that start with "group":
  $css .= <<CSS
table.graph##id## td[class|="group"] { padding: 0.2em; }
CSS
  if @groups > 0;

  $css .= <<CSS
table.graph##id## td {
  padding: 2px;
  background: inherit;
  white-space: nowrap;
  }
table.graph##id## span.l { float: left; }
table.graph##id## span.r { float: right; }
CSS
;

  # append CSS for edge cells (and their parts like va (vertical arrow
  # (left/right), vertical empty), etc)

  # eb	- empty bottom or arrow pointing down/up
  # el  - (vertical) empty left space of ver edge
  #       or empty vertical space on hor edge starts
  # lh  - edge label horizontal
  # le  - edge label, but empty (no label)
  # lv  - edge label vertical
  # sh  - shifted arrow horizontal (shift right)
  # sa  - shifted arrow horizontal (shift left for corners)
  # shl - shifted arrow horizontal (shift left)
  # sv  - shifted arrow vertical (pointing down)
  # su  - shifted arrow vertical (pointing up)

  $css .= <<CSS
table.graph##id## .va {
  vertical-align: middle;
  line-height: 1em;
  width: 0.4em;
  }
table.graph##id## .el {
  width: 0.1em;
  max-width: 0.1em;
  min-width: 0.1em;
  }
table.graph##id## .lh, table.graph##id## .lv {
  font-size: 0.8em;
  padding-left: 0.4em;
  }
table.graph##id## .sv, table.graph##id## .sh, table.graph##id## .shl, table.graph##id## .sa, table.graph##id## .su {
  max-height: 1em;
  line-height: 1em;
  position: relative;
  top: 0.55em;
  left: -0.3em;
  overflow: visible;
  }
table.graph##id## .sv, table.graph##id## .su {
  max-height: 0.5em;
  line-height: 0.5em;
  }
table.graph##id## .shl { left: 0.3em; }
table.graph##id## .sv { left: -0.5em; top: -0.4em; }
table.graph##id## .su { left: -0.5em; top: 0.4em; }
table.graph##id## .sa { left: -0.3em; top: 0; }
table.graph##id## .eb { max-height: 0; line-height: 0; height: 0; }
CSS
  # if we have edges
  if keys %{$self->{edges}}  > 0;

  # if we have nodes with rounded shapes:
  my $rounded = 0;
  for my $n (values %{$self->{nodes}})
    {
    $rounded ++ and last if $n->shape() =~ /circle|ellipse|rounded/;
    }

  $css .= <<CSS
table.graph##id## span.c { position: relative; top: 1.5em; }
table.graph##id## div.c { -moz-border-radius: 100%; border-radius: 100%; }
table.graph##id## div.r { -moz-border-radius: 1em; border-radius: 1em; }
CSS
  if $rounded > 0;

  # append CSS for group cells (only if we actually have groups)

  if (@groups > 0)
    {
    foreach my $group (@groups)
      {
      my $class = $group->class();

      my $border = $group->attribute('borderstyle'); 

      $class =~ s/.*\.//;	# leave only subclass
      $css .= Graph::Easy::Group::Cell->_css($self->{id}, $class, $border); 
      }
    }

  # replace the id with either '' or '123', depending on our ID
  $css =~ s/##id##/$id/g;

  $css;
  }

sub html_page_header
  {
  # return the HTML header for as_html_file()
  my ($self, $css) = @_;
  
  my $html = <<HTML
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
 <head>
 <meta http-equiv="Content-Type" content="text/html; charset=##charset##">
 <title>##title##</title>##CSS##
</head>
<body bgcolor=white text=black>
HTML
;

  $html =~ s/\n\z//;
  $html =~ s/##charset##/utf-8/g;
  my $t = $self->title();
  $html =~ s/##title##/$t/g;

  # insert CSS if requested
  $css = $self->css() unless defined $css;

  $html =~ s/##CSS##/\n <style type="text\/css">\n <!--\n $css -->\n <\/style>/ if $css ne '';
  $html =~ s/##CSS##//;

  $html;
  }

sub title
  {
  my $self = shift;

  my $title = $self->{att}->{graph}->{title};
  $title = $self->{att}->{graph}->{label} if !defined $title;
  $title = 'Untitled graph' if !defined $title;

  $title = $self->_un_escape($title, 1) if !$_[0] && $title =~ /\\[EGHNTL]/;
  $title;
  }

sub html_page_footer
  {
  # return the HTML footer for as_html_file()
  my $self = shift;

  "\n</body></html>\n";
  }

sub as_html_file
  {
  my $self = shift;

  $self->html_page_header() . $self->as_html() . $self->html_page_footer();
  }

#############################################################################

sub _caption
  {
  # create the graph label as caption
  my $self = shift;

  my ($caption,$switch_to_center) = $self->_label_as_html();

  return ('','') unless defined $caption && $caption ne '';

  my $bg = $self->raw_color_attribute('fill');

  my $style = ' style="';
  $style .= "background: $bg;" if $bg;
    
  # the font family
  my $f = $self->raw_attribute('font') || '';
  $style .= "font-family: $f;" if $f ne '';

  # the text color
  my $c = $self->raw_color_attribute('color');
  $style .= "color: $c;" if $c;

  # bold, italic, underline, incl. fontsize and align
  $style .= $self->text_styles_as_css();

  $style =~ s/;\z//;				# remove last ';'
  $style .= '"' unless $style eq ' style="';

  $style =~ s/style="\s/style="/;		# remove leading space

  my $link = $self->link();

  if ($link ne '')
    {
    # encode critical entities
    $link =~ s/\s/\+/g;				# space
    $link =~ s/'/%27/g;				# replace quotation marks
    $caption = "<a href='$link'>$caption</a>";
    }

  $caption = "<tr>\n  <td colspan=##cols##$style>$caption</td>\n</tr>\n";

  my $pos = $self->attribute('labelpos');

  ($caption,$pos);
  } 

sub as_html
  {
  # convert the graph to HTML+CSS
  my ($self) = shift;

  $self->layout() unless defined $self->{score};

  my $top = "\n" . $self->quoted_comment();
  
  my $cells = $self->{cells};
  my ($rows,$cols);
  
  my $max_x = undef;
  my $min_x = undef;

  # find all x and y occurances to sort them by row/columns
  for my $k (keys %$cells)
    {
    my ($x,$y) = split/,/, $k;
    my $node = $cells->{$k};

    $max_x = $x if !defined $max_x || $x > $max_x;
    $min_x = $x if !defined $min_x || $x < $min_x;
    
    # trace the rows we do have
    $rows->{$y}->{$x} = $node;
    # record all possible columns
    $cols->{$x} = undef;
    }
  
  $max_x = 1, $min_x = 1 unless defined $max_x;
  
  # number of cells in the table, maximum  
  my $max_cells = $max_x - $min_x + 1;
  
  my $groups = scalar $self->groups();

  my $id = $self->{id};

  $top .=  "\n<table class=\"graph$id\" cellpadding=0 cellspacing=0";
  $top .= ">\n";

  my $html = '';

  # prepare the graph label
  my ($caption,$pos) = $self->_caption();

  my $row_id = 0;
  # now run through all rows, and for each of them through all columns 
  for my $y (sort { ($a||0) <=> ($b||0) } keys %$rows)
    {

    # four rows at a time
    my $rs = [ [], [], [], [] ];

    # for all possible columns
    for my $x (sort { $a <=> $b } keys %$cols)
      {
      if (!exists $rows->{$y}->{$x})
	{
	# fill empty spaces with undef, but not for parts of multicelled objects:
	push @{$rs->[0]}, undef;
	next;
	}
      my $node = $rows->{$y}->{$x};
      next if $node->isa('Graph::Easy::Node::Cell');		# skip empty cells

      my $h = $node->as_html();

      if (ref($h) eq 'ARRAY')
        {
        #print STDERR '# expected 4 rows, but got ' . scalar @$h if @$h != 4;
        local $_; my $i = 0;
        push @{$rs->[$i++]}, $_ for @$h;
        }
      else
        {
        push @{$rs->[0]}, $h;
        }
      }

    ######################################################################
    # remove trailing empty tag-pairs, then replace undef with empty tags

    for my $row (@$rs)
      {
      pop @$row while (@$row > 0 && !defined $row->[-1]);
      local $_;
      foreach (@$row)
        {
        $_ = " <td colspan=4 rowspan=4></td>\n" unless defined $_;
        }
      }

    # now combine equal columns to shorten output
    for my $row (@$rs)
      {
      next;

      # append row to output
      my $i = 0;
      while ($i < @$row)
        {
        next if $row->[$i] =~ /border(:|-left)/;
#        next if $row->[$i] !~ />(\&nbsp;)?</;	# non-empty?
#        next if $row->[$i] =~ /span /;		# non-empty?
#        next if $row->[$i] =~ /^(\s|\n)*\z/;	# empty?

	# Combining these cells shows wierd artefacts when using the Firefox
	# WebDeveloper toolbar and outlining table cells, but it does not
	# seem to harm rendering in browsers:
        #next if $row->[$i] =~ /class="[^"]+ eb"/;	# is class=".. eb"

	# contains wo succ. cell?
        next if $row->[$i] =~ /(row|col)span.*\1span/m;	

        # count all sucessive equal ones
        my $j = $i + 1;

        $j++ while ($j < @$row && $row->[$j] eq $row->[$i]); # { $j++; }

        if ($j > $i + 1)
          {
          my $cnt = $j - $i - 1;

#         print STDERR "combining row $i to $j ($cnt) (\n'$row->[$i]'\n'$row->[$i+1]'\n'$row->[$j-1]'\n";

          # throw away
          splice (@$row, $i + 1, $cnt);

          # insert empty colspan if not already there
          $row->[$i] =~ s/<td/<td colspan=0/ unless $row->[$i] =~ /colspan/;
          # replace
          $row->[$i] =~ s/colspan=(\d+)/'colspan='.($1+$cnt*4)/e;
          }
        } continue { $i++; }
      }

    ######################################################################

    my $i = 0;    
    for my $row (@$rs)
      {
      # append row to output
      my $r = join('',@$row);

      if ($r !~ s/^[\s\n]*\z//)
	{
        # non empty rows get "\n</tr>"
        $r = "\n" . $r; # if length($r) > 0;
        }

      $html .= "<!-- row $row_id line $i -->\n" . '<tr>' . $r . "</tr>\n\n";
      $i++;
      }
    $row_id++;
    }

  ###########################################################################
  # finally insert the graph label
  $max_cells *= 4;					# 4 rows for each cell
  $caption =~ s/##cols##/$max_cells/ if defined $caption;

  $html .= $caption if $pos eq 'bottom';
  $top .= $caption if $pos eq 'top';

  $html = $top . $html;

  # remove empty trailing <tr></tr> pairs
  $html =~ s#(<tr></tr>\n\n)+\z##;

  $html .= "</table>\n";
 
  $html;
  } 

############################################################################# 
# as_boxart_*
  
sub as_boxart
  {
  # Create box-drawing art using Unicode characters - will return utf-8.
  my ($self) = shift;

  require Graph::Easy::As_ascii;
  
  # select Unicode box drawing characters
  $self->{_ascii_style} = 1;

  $self->_as_ascii(@_);
  }

sub as_boxart_html
  {
  # Output a box-drawing using Unicode, then return it as a HTML chunk
  # suitable to be embedded into an HTML page.
  my ($self) = shift;

  "<pre style='line-height: 1em; line-spacing: 0;'>\n" . 
    $self->as_boxart(@_) . 
    "\n</pre>\n";
  }

sub as_boxart_html_file
  {
  my $self = shift;

  $self->layout() unless defined $self->{score};

  $self->html_page_header(' ') . "\n" . 
    $self->as_boxart_html() . $self->html_page_footer();
  }

#############################################################################
# as_ascii_*

sub as_ascii
  {
  # Convert the graph to pretty ASCII art - will return utf-8.
  my $self = shift;

  # select 'ascii' characters
  $self->{_ascii_style} = 0;

  $self->_as_ascii(@_);
  }

sub _as_ascii
  {
  # Convert the graph to pretty ASCII or box art art - will return utf-8.
  my $self = shift;

  require Graph::Easy::As_ascii;
  require Graph::Easy::Layout::Grid;

  my $opt = ref($_[0]) eq 'HASH' ? $_[0] : { @_ };

  # include links?
  $self->{_links} = $opt->{links};

  $self->layout() unless defined $self->{score};

  # generate for each cell the width/height etc

  my ($rows,$cols,$max_x,$max_y) = $self->_prepare_layout('ascii');
  my $cells = $self->{cells};

  # offset where to draw the graph (non-zero if graph has label)
  my $y_start = 0;
  my $x_start = 0;

  my $align = $self->attribute('align');

  # get the label lines and their alignment
  my ($label,$aligns) = $self->_aligned_label($align);

  # if the graph has a label, reserve space for it
  my $label_pos = 'top';
  if (@$label > 0)
    {
    # insert one line over and below
    unshift @$label, '';   push @$label, '';
    unshift @$aligns, 'c'; push @$aligns, 'c';

    $label_pos = $self->attribute('graph','label-pos') || 'top';
    $y_start += scalar @$label if $label_pos eq 'top';
    $max_y += scalar @$label + 1;
    print STDERR "# Graph with label, position $label_pos\n" if $self->{debug};

    my $old_max_x = $max_x;
    # find out the dimensions of the label and make sure max_x is big enough
    for my $l (@$label)
      {
      $max_x = length($l)+2 if (length($l) > $max_x+2);
      }
    $x_start = int(($max_x - $old_max_x) / 2);
    }

  print STDERR "# Allocating framebuffer $max_x x $max_y\n" if $self->{debug};

  # generate the actual framebuffer for the output
  my $fb = Graph::Easy::Node->_framebuffer($max_x, $max_y);

  # output the label
  if (@$label > 0)
    {
    my $y = 0; $y = $max_y - scalar @$label if $label_pos eq 'bottom';
    Graph::Easy::Node->_printfb_aligned($fb, 0, $y, $max_x, $max_y, $label, $aligns, 'top');
    }

  # draw all cells into framebuffer
  foreach my $v (values %$cells)
    {
    next if $v->isa('Graph::Easy::Node::Cell');		# skip empty cells

    # get as ASCII box
    my $x = $cols->{ $v->{x} } + $x_start;
    my $y = $rows->{ $v->{y} } + $y_start;
 
    my @lines = split /\n/, $v->as_ascii($x,$y);
    # get position from cell
    for my $i (0 .. scalar @lines-1)
      {
      next if length($lines[$i]) == 0;
      # XXX TODO: framebuffer shouldn't be to small!
      $fb->[$y+$i] = ' ' x $max_x if !defined $fb->[$y+$i];
      substr($fb->[$y+$i], $x, length($lines[$i])) = $lines[$i]; 
      }
    }

  for my $y (0..$max_y)
    {
    $fb->[$y] = '' unless defined $fb->[$y];
    $fb->[$y] =~ s/\s+\z//;		# remove trailing whitespace
    }
  my $out = join("\n", @$fb) . "\n";

  $out =~ s/\n+\z/\n/;		# remove trailing empty lines

  # restore height/width of cells from minw/minh
  foreach my $v (values %$cells)
    {
    $v->{h} = $v->{minh};
    $v->{w} = $v->{minw};
    } 
  $out;				# return output
  }

sub as_ascii_html
  {
  # Convert the graph to pretty ASCII art, then return it as a HTML chunk
  # suitable to be embedded into an HTML page.
  my ($self) = shift;

  "<pre>\n" . $self->_as_ascii(@_) . "\n</pre>\n";
  }

#############################################################################
# as_txt, as_debug, as_graphviz

sub as_txt
  {
  require Graph::Easy::As_txt;

  _as_txt(@_);
  }

sub as_graphviz
  {
  require Graph::Easy::As_graphviz;

  _as_graphviz(@_);
  }

sub as_debug
  {
  require Graph::Easy::As_txt;
  eval { require Graph::Easy::As_svg; };

  my $self = shift;

  my $output = '';
 
  $output .= '# Using Graph::Easy v' . $Graph::Easy::VERSION . "\n";
  if ($Graph::Easy::As_svg::VERSION)
    {
    $output .= '# Using Graph::Easy::As_svg v' . $Graph::Easy::As_svg::VERSION . "\n";
    }
  $output .= '# Running Perl v' . $] . " under $^O\n";

  $output . "\n# Input normalized as_txt:\n\n" . $self->_as_txt(@_);
  }

#############################################################################
# as_vcg(as_gdl

sub as_vcg
  {
  require Graph::Easy::As_vcg;

  _as_vcg(@_);
  }

sub as_gdl
  {
  require Graph::Easy::As_vcg;

  _as_vcg(@_, { gdl => 1 });
  }

#############################################################################
# as_svg

sub as_svg
  {
  require Graph::Easy::As_svg;
  require Graph::Easy::Layout::Grid;

  _as_svg(@_);
  }

sub as_svg_file
  {
  require Graph::Easy::As_svg;
  require Graph::Easy::Layout::Grid;

  _as_svg( $_[0], { standalone => 1 } );
  }

sub svg_information
  {
  my ($self) = @_;

  require Graph::Easy::As_svg;
  require Graph::Easy::Layout::Grid;

  # if it doesn't exist, render as SVG and thus create it
  _as_svg(@_) unless $self->{svg_info};

  $self->{svg_info};
  }

#############################################################################
# as_graphml

sub as_graphml
  {
  require Graph::Easy::As_graphml;

  _as_graphml(@_);
  }

#############################################################################

sub add_edge
  {
  my ($self,$x,$y,$edge) = @_;
 
  my $uc = $self->{use_class};

  my $ec = $uc->{edge};
  $edge = $ec->new() unless defined $edge;
  $edge = $ec->new(label => $edge) unless ref($edge);

  $self->_croak("Adding an edge object twice is not possible")
    if (exists ($self->{edges}->{$edge->{id}}));

  $self->_croak("Cannot add edge $edge ($edge->{id}), it already belongs to another graph")
    if ref($edge->{graph}) && $edge->{graph} != $self;

  my $nodes = $self->{nodes};
  my $groups = $self->{groups};

  $self->_croak("Cannot add edge for undefined node names ($x -> $y)")
    unless defined $x && defined $y;

  my $xn = $x; my $yn = $y;
  $xn = $x->{name} if ref($x);
  $yn = $y->{name} if ref($y);

  # convert plain scalars to Node objects if nec.

  # XXX TODO: this might be a problem when adding an edge from a group with the same
  #           name as a node

  $x = $nodes->{$xn} if exists $nodes->{$xn};		# first look them up
  $y = $nodes->{$yn} if exists $nodes->{$yn};

  $x = $uc->{node}->new( $x ) unless ref $x;		# if this fails, create
  $y = $x if !ref($y) && $y eq $xn;			# make add_edge('A','A') work
  $y = $uc->{node}->new( $y ) unless ref $y;

  print STDERR "# add_edge '$x->{name}' ($x->{id}) -> '$y->{name}' ($y->{id}) (edge $edge->{id}) ($x -> $y)\n" if $self->{debug};

  for my $n ($x,$y)
    {
    $self->_croak("Cannot add node $n ($n->{name}), it already belongs to another graph")
      if ref($n->{graph}) && $n->{graph} != $self;
    }

  # Register the nodes and the edge with our graph object
  # and weaken the references. Be carefull to not needlessly
  # override and weaken again an already existing reference, this
  # is an O(N) operation in most Perl versions, and thus very slow.

  weaken($x->{graph} = $self) unless ref($x->{graph});
  weaken($y->{graph} = $self) unless ref($y->{graph});
  weaken($edge->{graph} = $self) unless ref($edge->{graph});

  # Store at the edge from where to where it goes for easier reference
  $edge->{from} = $x;
  $edge->{to} = $y;
 
  # store the edge at the nodes/groups, too
  $x->{edges}->{$edge->{id}} = $edge;
  $y->{edges}->{$edge->{id}} = $edge;

  # index nodes by their name so that we can find $x from $x->{name} fast
  my $store = $nodes; $store = $groups if $x->isa('Graph::Easy::Group');
  $store->{$x->{name}} = $x;
  $store = $nodes; $store = $groups if $y->isa('Graph::Easy::Group');
  $store->{$y->{name}} = $y;

  # index edges by "edgeid" so we can find them fast
  $self->{edges}->{$edge->{id}} = $edge;

  $self->{score} = undef;			# invalidate last layout

  wantarray ? ($x,$y,$edge) : $edge;
  }

sub add_anon_node
  {
  my ($self) = shift;

  $self->warn('add_anon_node does not take argumens') if @_ > 0;

  my $node = Graph::Easy::Node::Anon->new();

  $self->add_node($node);

  $node;
  }

sub add_node
  {
  my ($self,$x) = @_;

  my $n = $x;
  if (ref($x))
    {
    $n = $x->{name}; $n = '0' unless defined $n;
    }

  return $self->_croak("Cannot add node with empty name to graph.") if $n eq '';

  return $self->_croak("Cannot add node $x ($n), it already belongs to another graph")
    if ref($x) && ref($x->{graph}) && $x->{graph} != $self;

  my $no = $self->{nodes};
  # already exists?
  return $no->{$n} if exists $no->{$n};

  my $uc = $self->{use_class};
  $x = $uc->{node}->new( $x ) unless ref $x;

  # store the node
  $no->{$n} = $x;

  # Register the nodes and the edge with our graph object
  # and weaken the references. Be carefull to not needlessly
  # override and weaken again an already existing reference, this
  # is an O(N) operation in most Perl versions, and thus very slow.

  weaken($x->{graph} = $self) unless ref($x->{graph});

  $self->{score} = undef;			# invalidate last layout

  $x;
  }

sub add_nodes
  {
  my $self = shift;

  my @rc;
  for my $x (@_)
    {
    my $n = $x;
    if (ref($x))
      {
      $n = $x->{name}; $n = '0' unless defined $n;
      }

    return $self->_croak("Cannot add node with empty name to graph.") if $n eq '';

    return $self->_croak("Cannot add node $x ($n), it already belongs to another graph")
      if ref($x) && ref($x->{graph}) && $x->{graph} != $self;

    my $no = $self->{nodes};
    # this one already exists
    next if exists $no->{$n};

    my $uc = $self->{use_class};
    # make it work with read-only scalars:
    my $xx = $x;
    $xx = $uc->{node}->new( $x ) unless ref $x;

    # store the node
    $no->{$n} = $xx;

    # Register the nodes and the edge with our graph object
    # and weaken the references. Be carefull to not needlessly
    # override and weaken again an already existing reference, this
    # is an O(N) operation in most Perl versions, and thus very slow.

    weaken($xx->{graph} = $self) unless ref($xx->{graph});

    push @rc, $xx;
    }

  $self->{score} = undef;			# invalidate last layout

  @rc;
  }

#############################################################################
#############################################################################
# Cloning/merging of graphs and objects

sub copy
  {
  # create a copy of this graph and return it as new graph
  my $self = shift;

  my $new = Graph::Easy->new();

  # clone all the settings
  for my $k (keys %$self)
    {
    $new->{$k} = $self->{$k} unless ref($self->{$k});
    }

  for my $g (keys %{$self->{groups}})
    {
    my $ng = $new->add_group($g);
    # clone the attributes
    $ng->{att} = $self->_clone( $self->{groups}->{$g}->{att} );
    }
  for my $n (values %{$self->{nodes}})
    {
    my $nn = $new->add_node($n->{name});
    # clone the attributes
    $nn->{att} = $self->_clone( $n->{att} );
    # restore group membership for the node
    $nn->add_to_group( $n->{group}->{name} ) if $n->{group};
    }
  for my $e (values %{$self->{edges}})
    {
    my $ne = $new->add_edge($e->{from}->{name}, $e->{to}->{name} );
    # clone the attributes
    $ne->{att} = $self->_clone( $e->{att} );
    }
  # clone the attributes
  $new->{att} = $self->_clone( $self->{att});

  $new;
  }

sub _clone
  {
  # recursively clone a data structure
  my ($self,$in) = @_;

  my $out = { };

  for my $k (keys %$in)
    {
    if (ref($k) eq 'HASH')
      {
      $out->{$k} = $self->_clone($in->{$k});
      }
    elsif (ref($k))
      {
      $self->error("Can't clone $k");
      }
    else
      {
      $out->{$k} = $in->{$k};
      }
    }
  $out;
  }

sub merge_nodes
  {
  # Merge two nodes, by dropping all connections between them, and then
  # drawing all connections from/to $B to $A, then drop $B
  my ($self, $A, $B, $joiner) = @_;

  $A = $self->node($A) unless ref($A);
  $B = $self->node($B) unless ref($B);

  # if the node is part of a group, deregister it first from there
  $B->{group}->del_node($B) if ref($B->{group});

  my @edges = values %{$A->{edges}};

  # drop all connections from A --> B
  for my $edge (@edges)
    {
    next unless $edge->{to} == $B;

#    print STDERR "# dropping $edge->{from}->{name} --> $edge->{to}->{name}\n";
    $self->del_edge($edge);
    }

  # Move all edges from/to B over to A, but drop "B --> B" and "B --> A".
  for my $edge (values %{$B->{edges}})
    {
    # skip if going from B --> A or B --> B
    next if $edge->{to} == $A || ($edge->{to} == $B && $edge->{from} == $B);

#    print STDERR "# moving $edge->{from}->{name} --> $edge->{to}->{name} to ";

    $edge->{from} = $A if $edge->{from} == $B;
    $edge->{to} = $A if $edge->{to} == $B;

#   print STDERR " $edge->{from}->{name} --> $edge->{to}->{name}\n";

    delete $B->{edges}->{$edge->{id}};
    $A->{edges}->{$edge->{id}} = $edge;
    }

  # should we join the label from B to A?
  $A->set_attribute('label', $A->label() . $joiner . $B->label() ) if defined $joiner;

  $self->del_node($B);

  $self;
  }

#############################################################################
# deletion

sub del_node
  {
  my ($self, $node) = @_;

  # make object
  $node = $self->{nodes}->{$node} unless ref($node);

  # doesn't exist, so we don't need to do anything
  return unless ref($node);

  # if node is part of a group, delete it there, too
  $node->{group}->del_node($node) if ref $node->{group};

  delete $self->{nodes}->{$node->{name}};

  # delete all edges from/to this node
  for my $edge (values %{$node->{edges}})
    {
    # drop the edge from our global edge list
    delete $self->{edges}->{$edge->{id}};
 
    my $to = $edge->{to}; my $from = $edge->{from};

    # drop the edge from the other node
    delete $from->{edges}->{$edge->{id}} if $from != $node;
    delete $to->{edges}->{$edge->{id}} if $to != $node;
    }

  # decouple node from the graph
  $node->{graph} = undef;
  # reset cached size
  $node->{w} = undef;

  # drop all edges from the node locally
  $node->{edges} = { };

  # if the node is a child of another node, deregister it there
  delete $node->{origin}->{children}->{$node->{id}} if defined $node->{origin};

  $self->{score} = undef;			# invalidate last layout

  $self;
  }

sub del_edge
  {
  my ($self, $edge) = @_;

  $self->_croak("del_edge() needs an object") unless ref $edge;

  # if edge is part of a group, delete it there, too
  $edge->{group}->_del_edge($edge) if ref $edge->{group};

  my $to = $edge->{to}; my $from = $edge->{from};

  # delete the edge from the nodes
  delete $from->{edges}->{$edge->{id}};
  delete $to->{edges}->{$edge->{id}};
  
  # drop the edge from our global edge list
  delete $self->{edges}->{$edge->{id}};

  $edge->{from} = undef;
  $edge->{to} = undef;

  $self;
  }

#############################################################################
# group management

sub add_group
  {
  # add a group object
  my ($self,$group) = @_;

  my $uc = $self->{use_class};

  # group with that name already exists?
  my $name = $group; 
  $group = $self->{groups}->{ $group } unless ref $group;

  # group with that name doesn't exist, so create new one
  $group = $uc->{group}->new( name => $name ) unless ref $group;

  # index under the group name for easier lookup
  $self->{groups}->{ $group->{name} } = $group;

  # register group with ourself and weaken the reference
  $group->{graph} = $self;
  {
    no warnings; # dont warn on already weak references
    weaken($group->{graph});
  } 
  $self->{score} = undef;			# invalidate last layout

  $group;
  }

sub del_group
  {
  # delete group
  my ($self,$group) = @_;

  delete $self->{groups}->{ $group->{name} };
 
  $self->{score} = undef;			# invalidate last layout

  $self;
  }

sub group
  {
  # return group by name
  my ($self,$name) = @_;

  $self->{groups}->{ $name };
  }

sub groups
  {
  # return number of groups (or groups as object list)
  my ($self) = @_;

  return sort { $a->{name} cmp $b->{name} } values %{$self->{groups}}
    if wantarray;

  scalar keys %{$self->{groups}};
  }

sub groups_within
  {
  # Return the groups that are directly inside this graph/group. The optional
  # level is either -1 (meaning return all groups contained within), or a
  # positive number indicating how many levels down we need to go.
  my ($self, $level) = @_;

  $level = -1 if !defined $level || $level < 0;

  # inline call to $self->groups;
  if ($level == -1)
    {
    return sort { $a->{name} cmp $b->{name} } values %{$self->{groups}}
      if wantarray;

    return scalar keys %{$self->{groups}};
    }

  my $are_graph = $self->{graph} ? 0 : 1;

  # get the groups at level 0
  my $current = 0;
  my @todo;
  for my $g (values %{$self->{groups}})
    {
    # no group set => belongs to graph, set to ourself => belongs to ourself
    push @todo, $g if ( ($are_graph && !defined $g->{group}) || $g->{group} == $self);
    }

  if ($level == 0)
    {
    return wantarray ? @todo : scalar @todo;
    }

  # we need to recursively count groups until the wanted level is reached
  my @cur = @todo;
  for my $g (@todo)
    {
    # _groups_within() is defined in Graph::Easy::Group
    $g->_groups_within(1, $level, \@cur);
    }

  wantarray ? @cur : scalar @cur;
  }

sub anon_groups
  {
  # return all anon groups as objects
  my ($self) = @_;

  my $n = $self->{groups};

  if (!wantarray)
    {
    my $count = 0;
    for my $group (values %$n)
      {
      $count++ if $group->is_anon();
      }
    return $count;
    }

  my @anon = ();
  for my $group (values %$n)
    {
    push @anon, $group if $group->is_anon();
    }
  @anon;
  }

sub use_class
  {
  # use the provided class for generating objects of the type $object
  my ($self, $object, $class) = @_;

  $self->_croak("Expected one of node, edge or group, but got $object")
    unless $object =~ /^(node|group|edge)\z/;

  $self->{use_class}->{$object} = $class;

  $self;  
  }

#############################################################################
#############################################################################
# Support for Graph interface to make Graph::Maker happy:

sub add_vertex
  {
  my ($self,$x) = @_;
  
  $self->add_node($x);
  $self;
  }

sub add_vertices
  {
  my ($self) = shift;
  
  $self->add_nodes(@_);
  $self;
  }

sub add_path
  {
  my ($self) = shift;

  my $first = shift;

  while (@_)
    {
    my $second = shift;
    $self->add_edge($first, $second );
    $first = $second; 
    }
  $self;
  }

sub add_cycle
  {
  my ($self) = shift;

  my $first = shift; my $a = $first;

  while (@_)
    {
    my $second = shift;
    $self->add_edge($first, $second );
    $first = $second; 
    }
  # complete the cycle
  $self->add_edge($first, $a);
  $self;
  }

sub has_edge
  {
  # return true if at least one edge between X and Y exists
  my ($self, $x, $y) = @_;

  # turn plaintext scalars into objects 
  $x = $self->{nodes}->{$x} unless ref $x;
  $y = $self->{nodes}->{$y} unless ref $y;

  # node does not exist => edge does not exist
  return 0 unless ref($x) && ref($y);

  scalar $x->edges_to($y) ? 1 : 0;
  }

sub set_vertex_attribute
  {
  my ($self, $node, $name, $value) = @_;

  $node = $self->add_node($node);
  $node->set_attribute($name,$value);

  $self;
  }

sub get_vertex_attribute
  {
  my ($self, $node, $name) = @_;

  $self->node($node)->get_attribute($name);
  }

#############################################################################
#############################################################################
# Animation support

sub animation_as_graph
  {
  my $self = shift;

  my $graph = Graph::Easy->new();

  $graph->add_node('onload');

  # XXX TODO

  $graph;
  }

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Graph::Easy - Convert or render graphs (as ASCII, HTML, SVG or via Graphviz)

=head1 SYNOPSIS

	use Graph::Easy;
	
	my $graph = Graph::Easy->new();

	# make a fresh copy of the graph
	my $new_graph = $graph->copy();

	$graph->add_edge ('Bonn', 'Berlin');

	# will not add it, since it already exists
	$graph->add_edge_once ('Bonn', 'Berlin');

	print $graph->as_ascii( ); 		# prints:

	# +------+     +--------+
	# | Bonn | --> | Berlin |
	# +------+     +--------+

	#####################################################
	# alternatively, let Graph::Easy parse some text:

	my $graph = Graph::Easy->new( '[Bonn] -> [Berlin]' );

	#####################################################
	# slightly more verbose way:

	my $graph = Graph::Easy->new();

	my $bonn = $graph->add_node('Bonn');
	$bonn->set_attribute('border', 'solid 1px black');

	my $berlin = $graph->add_node('Berlin');

	$graph->add_edge ($bonn, $berlin);

	print $graph->as_ascii( );

	# You can use plain scalars as node names and for the edge label:
	$graph->add_edge ('Berlin', 'Frankfurt', 'via train');

	# adding edges with attributes:

	my $edge = Graph::Easy::Edge->new();
	$edge->set_attributes( {
		label => 'train',
		style => 'dotted',
		color => 'red',
	} );

	# now with the optional edge object
	$graph->add_edge ($bonn, $berlin, $edge);

	# raw HTML section
	print $graph->as_html( );

	# complete HTML page (with CSS)
	print $graph->as_html_file( );

	# Other possibilities:

	# SVG (possible after you installed Graph::Easy::As_svg):
	print $graph->as_svg( );

	# Graphviz:
	my $graphviz = $graph->as_graphviz();
	open $DOT, '|dot -Tpng -o graph.png' or die ("Cannot open pipe to dot: $!");
	print $DOT $graphviz;
	close $DOT;

	# Please see also the command line utility 'graph-easy'

=head1 DESCRIPTION

C<Graph::Easy> lets you generate graphs consisting of various shaped
nodes connected by edges (with optional labels).

It can read and write graphs in a varity of formats, as well as render
them via its own grid-based layouter.

Since the layouter works on a grid (manhattan layout), the output is
most useful for flow charts, network diagrams, or hierarchy trees.

X<graph>
X<drawing>
X<diagram>
X<flowchart>
X<layout>
X<manhattan>

=head2 Input

Apart from driving the module with Perl code, you can also use
C<Graph::Easy::Parser> to parse graph descriptions like:

	[ Bonn ]      --> [ Berlin ]
	[ Frankfurt ] <=> [ Dresden ]
	[ Bonn ]      --  [ Frankfurt ]

See the C<EXAMPLES> section below for how this might be rendered.

=head2 Creating graphs

First, create a graph object:

	my $graph = Graph::Easy->new();

Then add a node to it:

	my $node = $graph->add_node('Koblenz');

Don't worry, adding the node again will do nothing:

	$node = $graph->add_node('Koblenz');

You can get back a node by its name with C<node()>:

	$node = $graph->node('Koblenz');

You can either add another node:

	my $second = $graph->node('Frankfurt');

Or add an edge straight-away:

	my ($first,$second,$edge) = $graph->add_edge('Mainz','Ulm');

Adding the edge the second time creates another edge from 'Mainz' to 'Ulm':

	my $other_edge;
	 ($first,$second,$other_edge) = $graph->add_edge('Mainz','Ulm');

This can be avoided by using C<add_edge_once()>:

	my $edge = $graph->add_edge_once('Mainz','Ulm');
	if (defined $edge)
	  {
	  # the first time the edge was added, do something with it
	  $edge->set_attribute('color','blue');
	  }

You can set attributes on nodes and edges:

	$node->attribute('fill', 'yellow');
	$edge->attribute('label', 'train');

It is possible to add an edge with a label:

	$graph->add_edge('Cottbus', 'Berlin', 'my label');

You can also add self-loops:

	$graph->add_edge('Bremen','Bremen');

Adding multiple nodes is easy:

	my ($bonn,$rom) = Graph::Easy->add_nodes('Bonn','Rom');

You can also have subgraphs (these are called groups):

	my ($group) = Graph::Easy->add_group('Cities');

Only nodes can be part of a group, edges are automatically considered
to be in the group if they lead from one node inside the group to
another node in the same group. There are multiple ways to add one or
more nodes into a group:

	$group->add_member($bonn);
	$group->add_node($rom);
	$group->add_nodes($rom,$bonn);

For more options please see the online manual: 
L<http://bloodgate.com/perl/graph/manual/> .

=head2 Output

The output can be done in various styles:

=over 2

=item ASCII ART

Uses things like C<+>, C<-> C<< < >> and C<|> to render the boxes.

=item BOXART

Uses Unicode box art drawing elements to output the graph.

=item HTML

HTML tables with CSS making everything "pretty".

=item SVG

Creates a Scalable Vector Graphics output.

=item Graphviz

Creates graphviz code that can be feed to 'dot', 'neato' or similar programs.

=item GraphML

Creates a textual description of the graph in the GraphML format.

=item GDL/VCG

Creates a textual description of the graph in the VCG or GDL (Graph
Description Language) format.

=back

X<ascii>
X<html>
X<svg>
X<boxart>
X<graphviz>
X<dot>
X<neato>

=head1 EXAMPLES

The following examples are given in the simple text format that is understood
by L<Graph::Easy::Parser|Graph::Easy::Parser>.

You can also see many more examples at:

L<http://bloodgate.com/perl/graph/>

=head2 One node

The most simple graph (apart from the empty one :) is a graph consisting of
only one node:

	[ Dresden ]

=head2 Two nodes

A simple graph consisting of two nodes, linked together by a directed edge:

	[ Bonn ] -> [ Berlin ]

=head2 Three nodes

A graph consisting of three nodes, and both are linked from the first:

	[ Bonn ] -> [ Berlin ]
	[ Bonn ] -> [ Hamburg ]

=head2 Three nodes in a chain

A graph consisting of three nodes, showing that you can chain connections together:

	[ Bonn ] -> [ Berlin ] -> [ Hamburg ]

=head2 Two not connected graphs

A graph consisting of two separate parts, both of them not connected
to each other:

	[ Bonn ] -> [ Berlin ]
	[ Freiburg ] -> [ Hamburg ]

=head2 Three nodes, interlinked

A graph consisting of three nodes, and two of the are connected from
the first node:

	[ Bonn ] -> [ Berlin ]
	[ Berlin ] -> [ Hamburg ]
	[ Bonn ] -> [ Hamburg ]

=head2 Different edge styles

A graph consisting of a couple of nodes, linked with the
different possible edge styles.

	[ Bonn ] <-> [ Berlin ]		# bidirectional
	[ Berlin ] ==> [ Rostock ]	# double
	[ Hamburg ] ..> [ Altona ]	# dotted
	[ Dresden ] - > [ Bautzen ]	# dashed
	[ Leipzig ] ~~> [ Kirchhain ]	# wave
	[ Hof ] .-> [ Chemnitz ]	# dot-dash
	[ Magdeburg ] <=> [ Ulm ]	# bidrectional, double etc
	[ Magdeburg ] -- [ Ulm ]	# arrow-less edge

More examples at: L<http://bloodgate.com/perl/graph/>

=head1 ANIMATION SUPPORT

B<Note: Animations are not yet implemented!>

It is possible to add animations to a graph. This is done by
adding I<steps> via the pseudo-class C<step>:

	step.0 {
	  target: Bonn;		# find object with id=Bonn, or
				# if this fails, the node named
				# "Bonn".
	  animate: fill:	# animate this attribute
	  from: yellow;		# start value (0% of duration)
	  via: red;		# at 50% of the duration
	  to: yellow;		# and 100% of duration
	  wait: 0;		# after triggering, wait so many seconds
	  duration: 5;		# entire time to go from "from" to "to"
	  trigger: onload;	# when to trigger this animation
	  repeat: 2;		# how often to repeat ("2" means two times)
				# also "infinite", then "next" will be ignored
	  next: 1;		# which step to take after repeat is up
	}
	step.1 {
	  from: white;		# set to white
	  to: white;
	  duration: 0.1;	# 100ms
	  next: 0;		# go back to step.0
	}

Here two steps are created, I<0> and I<1> and the animation will
be going like this:

                               0.1s
	                     +-------------------------------+
	                     v                               |
	+--------+  0s   +--------+  5s   +--------+  5s   +--------+
	| onload | ----> | step.0 | ----> | step.0 | ----> | step.1 |
	+--------+       +--------+       +--------+       +--------+

You can generate a a graph with the animation flow via
C<animation_as_graph()>.

=head2 Output

Currently no output formats supports animations yet.

=head1 METHODS

C<Graph::Easy> supports the following methods:

=head2 new()

        use Graph::Easy;

        my $graph = Graph::Easy->new( );
        
Creates a new, empty C<Graph::Easy> object.

Takes optinal a hash reference with a list of options. The following are
valid options:

	debug			if true, enables debug output
	timeout			timeout (in seconds) for the layouter
	fatal_errors		wrong attributes are fatal errors, default: true
	strict			test attribute names for being valid, default: true
	undirected		create an undirected graph, default: false

=head2 copy()

    my $copy = $graph->copy( );

Create a copy of this graph and return it as a new Graph::Easy object.

=head2 error()

	my $error = $graph->error();

Returns the last error or '' for none.
Optionally, takes an error message to be set.

	$graph->error( 'Expected Foo, but found Bar.' );

See L<warn()> on how to catch error messages. See also L<non_fatal_errors()>
on how to turn errors into warnings.

=head2 warn()

	my $warning = $graph->warn();

Returns the last warning or '' for none.
Optionally, takes a warning message to be output to STDERR:

	$graph->warn( 'Expected Foo, but found Bar.' );

If you want to catch warnings from the layouter, enable catching
of warnings or errors:

	$graph->catch_messages(1);

	# Or individually:
	# $graph->catch_warnings(1);
	# $graph->catch_errors(1);

	# something which warns or throws an error:
	...

	if ($graph->error())
	  {
	  my @errors = $graph->errors();
	  }
	if ($graph->warning())
	  {
	  my @warnings = $graph->warnings();
	  }

See L<Graph::Easy::Base> for more details on error/warning message capture.

=head2 add_edge()

	my ($first, $second, $edge) = $graph->add_edge( 'node 1', 'node 2');

=head2 add_edge()

	my ($first, $second, $edge) = $graph->add_edge( 'node 1', 'node 2');
	my $edge = $graph->add_edge( $x, $y, $edge);
	$graph->add_edge( $x, $y);

Add an edge between nodes X and Y. The optional edge object defines
the style of the edge, if not present, a default object will be used.

When called in scalar context, will return C<$edge>. In array/list context
it will return the two nodes and the edge object.

C<$x> and C<$y> should be either plain scalars with the names of
the nodes, or objects of L<Graph::Easy::Node|Graph::Easy::Node>,
while the optional C<$edge> should be L<Graph::Easy::Edge|Graph::Easy::Edge>.

Note: C<Graph::Easy> graphs are multi-edged, and adding the same edge
twice will result in two edges going from C<$x> to C<$y>! See
C<add_edge_once()> on how to avoid that.

You can also use C<edge()> to check whether an edge from X to Y already exists
in the graph.
 
=head2 add_edge_once()

	my ($first, $second, $edge) = $graph->add_edge_once( 'node 1', 'node 2');
	my $edge = $graph->add_edge_once( $x, $y, $edge);
	$graph->add_edge_once( $x, $y);

	if (defined $edge)
	  {
	  # got added once, so do something with it
	  $edge->set_attribute('label','unique');
	  }

Adds an edge between nodes X and Y, unless there exists already
an edge between these two nodes. See C<add_edge()>.

Returns undef when an edge between X and Y already exists.

When called in scalar context, will return C<$edge>. In array/list context
it will return the two nodes and the edge object.

=head2 flip_edges()

	my $graph = Graph::Easy->new();
	$graph->add_edge('Bonn','Berlin');
	$graph->add_edge('Berlin','Bonn');

	print $graph->as_ascii();

	#   +--------------+
	#   v              |
	# +--------+     +------+
	# | Berlin | --> | Bonn |
	# +--------+     +------+

	$graph->flip_edges('Bonn', 'Berlin');

	print $graph->as_ascii();

	#   +--------------+
	#   |              v
	# +--------+     +------+
	# | Berlin | --> | Bonn |
	# +--------+     +------+

Turn around (transpose) all edges that are going from the first node to the
second node.

X<transpose>

=head2 add_node()

	my $node = $graph->add_node( 'Node 1' );
	# or if you already have a Graph::Easy::Node object:
	$graph->add_node( $x );

Add a single node X to the graph. C<$x> should be either a
C<Graph::Easy::Node> object, or a unique name for the node. Will do
nothing if the node already exists in the graph.

It returns an L<Graph::Easy::Node> object.

=head2 add_anon_node()

	my $anon_node = $graph->add_anon_node( );

Creates a single, anonymous node and adds it to the graph, returning the
C<Graph::Easy::Node::Anon> object.

The created node is equal to one created via C< [ ] > in the Graph::Easy
text description.

=head2 add_nodes()

	my @nodes = $graph->add_nodes( 'Node 1', 'Node 2' );

Add all the given nodes to the graph. The arguments should be either a
C<Graph::Easy::Node> object, or a unique name for the node. Will do
nothing if the node already exists in the graph.

It returns a list of L<Graph::Easy::Node> objects.

=head2 rename_node()

	$node = $graph->rename_node($node, $new_name);

Changes the name of a node. If the passed node is not part of
this graph or just a string, it will be added with the new
name to this graph.

If the node was part of another graph, it will be deleted there and added
to this graph with the new name, effectively moving the node from the old
to the new graph and renaming it at the same time.

=head2 del_node()

	$graph->del_node('Node name');
	$graph->del_node($node);

Delete the node with the given name from the graph.

=head2 del_edge()

	$graph->del_edge($edge);

Delete the given edge object from the graph. You can use C<edge()> to find
an edge from Node A to B:

	$graph->del_edge( $graph->edge('A','B') );

=head2 merge_nodes()

	$graph->merge_nodes( $first_node, $second_node );
	$graph->merge_nodes( $first_node, $second_node, $joiner );

Merge two nodes. Will delete all connections between the two nodes, then
move over any connection to/from the second node to the first, then delete
the second node from the graph.

Any attributes on the second node will be lost.

If present, the optional C<< $joiner >> argument will be used to join
the label of the second node to the label of the first node. If not
present, the label of the second node will be dropped along with all
the other attributes:

	my $graph = Graph::Easy->new('[A]->[B]->[C]->[D]');

	# this produces "[A]->[C]->[D]"
	$graph->merge_nodes( 'A', 'B' );

	# this produces "[A C]->[D]"
	$graph->merge_nodes( 'A', 'C', ' ' );

	# this produces "[A C \n D]", note single quotes on the third argument!
	$graph->merge_nodes( 'A', 'C', ' \n ' );

=head2 get_attribute()

	my $value = $graph->get_attribute( $class, $name );

Return the value of attribute C<$name> from class C<$class>.

Example:

	my $color = $graph->attribute( 'node', 'color' );

You can also call all the various attribute related methods on members of the
graph directly, for instance:

	$node->get_attribute('label');
	$edge->get_attribute('color');
	$group->get_attribute('fill');

=head2 attribute()

	my $value = $graph->attribute( $class, $name );

Is an alias for L<get_attribute>.

=head2 color_attribute()

	# returns f.i. #ff0000
	my $color = $graph->get_color_attribute( 'node', 'color' );

Just like L<get_attribute()>, but only for colors, and returns them as hex,
using the current colorscheme.

=head2 get_color_attribute()

Is an alias for L<color_attribute()>.

=head2 get_attributes()

	my $att = $object->get_attributes();

Return all effective attributes on this object (graph/node/group/edge) as
an anonymous hash ref. This respects inheritance and default values.

Note that this does not include custom attributes.

See also L<get_custom_attributes> and L<raw_attributes()>.

=head2 get_custom_attributes()

	my $att = $object->get_custom_attributes();

Return all the custom attributes on this object (graph/node/group/edge) as
an anonymous hash ref.

=head2 custom_attributes()

	my $att = $object->custom_attributes();

C<< custom_attributes() >> is an alias for L<< get_custom_attributes >>.

=head2 raw_attributes()

	my $att = $object->raw_attributes();

Return all set attributes on this object (graph, node, group or edge) as
an anonymous hash ref. Thus you get all the locally active attributes
for this object.

Inheritance is respected, e.g. attributes that have the value "inherit"
and are inheritable, will be inherited from the base class.

But default values for unset attributes are skipped. Here is an example:

	node { color: red; }

	[ A ] { class: foo; color: inherit; }

This will return:

	{ class => foo, color => red }

As you can see, attributes like C<background> etc. are not included, while
the color value was inherited properly.

See also L<get_attributes()>.

=head2 default_attribute()

	my $def = $graph->default_attribute($class, 'fill');

Returns the default value for the given attribute B<in the class>
of the object.

The default attribute is the value that will be used if
the attribute on the object itself, as well as the attribute
on the class is unset.

To find out what attribute is on the class, use the three-arg form
of L<attribute> on the graph:

	my $g = Graph::Easy->new();
	my $node = $g->add_node('Berlin');

	print $node->attribute('fill'), "\n";		# print "white"
	print $node->default_attribute('fill'), "\n";	# print "white"
	print $g->attribute('node','fill'), "\n";	# print "white"

	$g->set_attribute('node','fill','red');		# class is "red"
	$node->set_attribute('fill','green');		# this object is "green"

	print $node->attribute('fill'), "\n";		# print "green"
	print $node->default_attribute('fill'), "\n";	# print "white"
	print $g->attribute('node','fill'), "\n";	# print "red"

See also L<raw_attribute()>.

=head2 raw_attribute()

	my $value = $object->raw_attribute( $name );

Return the value of attribute C<$name> from the object it this
method is called on (graph, node, edge, group etc.). If the
attribute is not set on the object itself, returns undef.

This method respects inheritance, so an attribute value of 'inherit'
on an object will make the method return the inherited value:

	my $g = Graph::Easy->new();
	my $n = $g->add_node('A');

	$g->set_attribute('color','red');

	print $n->raw_attribute('color');		# undef
	$n->set_attribute('color','inherit');
	print $n->raw_attribute('color');		# 'red'

See also L<attribute()>.

=head2 raw_color_attribute()

	# returns f.i. #ff0000
	my $color = $graph->raw_color_attribute('color' );

Just like L<raw_attribute()>, but only for colors, and returns them as hex,
using the current colorscheme.

If the attribute is not set on the object, returns C<undef>.

=head2 raw_attributes()

	my $att = $object->raw_attributes();

Returns a hash with all the raw attributes of that object.
Attributes that are no set on the object itself, but on
the class this object belongs to are B<not> included.

This method respects inheritance, so an attribute value of 'inherit'
on an object will make the method return the inherited value.

=head2 set_attribute()

	# Set the attribute on the given class.
	$graph->set_attribute( $class, $name, $val );

	# Set the attribute on the graph itself. This is synonymous
	# to using 'graph' as class in the form above.
	$graph->set_attribute( $name, $val );

Sets a given attribute named C<$name> to the new value C<$val> in the class
specified in C<$class>.

Example:

	$graph->set_attribute( 'graph', 'gid', '123' );

The class can be one of C<graph>, C<edge>, C<node> or C<group>. The last
three can also have subclasses like in C<node.subclassname>.

You can also call the various attribute related methods on members of the
graph directly, for instance:

	$node->set_attribute('label', 'my node');
	$edge->set_attribute('color', 'red');
	$group->set_attribute('fill', 'green');

=head2 set_attributes()

	$graph->set_attributes( $class, $att );

Given a class name in C<$class> and a hash of mappings between attribute names
and values in C<$att>, will set all these attributes.

The class can be one of C<graph>, C<edge>, C<node> or C<group>. The last
three can also have subclasses like in C<node.subclassname>.

Example:

	$graph->set_attributes( 'node', { color => 'red', background => 'none' } );

=head2 del_attribute()

	$graph->del_attribute('border');

Delete the attribute with the given name from the object.

You can also call the various attribute related methods on members of the
graph directly, for instance:

	$node->del_attribute('label');
	$edge->del_attribute('color');
	$group->del_attribute('fill');

=head2 unquote_attribute()

	# returns '"Hello World!"'
	my $value = $self->unquote_attribute('node','label','"Hello World!"');
	# returns 'red'
	my $color = $self->unquote_attribute('node','color','"red"');

Return the attribute unquoted except for labels and titles, that is it removes
double quotes at the start and the end of the string, unless these are
escaped with a backslash.

=head2 border_attribute()

  	my $border = $graph->border_attribute();

Return the combined border attribute like "1px solid red" from the
border(style|color|width) attributes.

=head2 split_border_attributes()

  	my ($style,$width,$color) = $graph->split_border_attribute($border);

Split the border attribute (like "1px solid red") into the three different parts.

=head2 quoted_comment()

	my $cmt = $node->comment();

Comment of this object, quoted suitable as to be embedded into HTML/SVG.
Returns the empty string if this object doesn't have a comment set.

=head2 flow()

	my $flow = $graph->flow();

Returns the flow of the graph, as absolute number in degress.

=head2 source_nodes()

	my @roots = $graph->source_nodes();

Returns all nodes that have only outgoing edges, e.g. are the root of a tree,
in no particular order.

Isolated nodes (no edges at all) will B<not> be included, see
L<predecessorless_nodes()> to get these, too.

In scalar context, returns the number of source nodes.

=head2 predecessorless_nodes()

	my @roots = $graph->predecessorless_nodes();

Returns all nodes that have no incoming edges, regardless of whether
they have outgoing edges or not, in no particular order.

Isolated nodes (no edges at all) B<will> be included in the list.

See also L<source_nodes()>.

In scalar context, returns the number of predecessorless nodes.

=head2 root_node()

	my $root = $graph->root_node();

Return the root node as L<Graph::Easy::Node> object, if it was
set with the 'root' attribute.

=head2 timeout()

	print $graph->timeout(), " seconds timeout for layouts.\n";
	$graph->timeout(12);

Get/set the timeout for layouts in seconds. If the layout process did not
finish after that time, it will be stopped and a warning will be printed.

The default timeout is 5 seconds.

=head2 strict()

	print "Graph has strict checking\n" if $graph->strict();
	$graph->strict(undef);		# disable strict attribute checks

Get/set the strict option. When set to a true value, all attribute names and
values will be strictly checked and unknown/invalid one will be rejected.

This option is on by default.

=head2 type()

	print "Graph is " . $graph->type() . "\n";

Returns the type of the graph as string, either "directed" or "undirected".

=head2 layout()

	$graph->layout();
	$graph->layout( type => 'force', timeout => 60 );

Creates the internal structures to layout the graph. 

This method will be called automatically when you call any of the
C<as_FOO> methods or C<output()> as described below.

The options are:

	type		the type of the layout, possible values:
			'force'		- force based layouter
			'adhoc'		- the default layouter
	timeout		timeout in seconds

See also: L<timeout()>.

=head2 output_format()

	$graph->output_format('html');

Set the outputformat. One of 'html', 'ascii', 'graphviz', 'svg' or 'txt'.
See also L<output()>.

=head2 output()

	my $out = $graph->output();

Output the graph in the format set by C<output_format()>.

=head2 as_ascii()

	print $graph->as_ascii();

Return the graph layout in ASCII art, in utf-8.

=head2 as_ascii_file()

	print $graph->as_ascii_file();

Is an alias for L<as_ascii>.

=head2 as_ascii_html()

	print $graph->as_ascii_html();

Return the graph layout in ASCII art, suitable to be embedded into an HTML
page. Basically it wraps the output from L<as_ascii()> into
C<< <pre> </pre> >> and inserts real HTML links. The returned
string is in utf-8.

=head2 as_boxart()

	print $graph->as_box();

Return the graph layout as box drawing using Unicode characters (in utf-8,
as always).

=head2 as_boxart_file()

	print $graph->as_boxart_file();

Is an alias for C<as_box>.

=head2 as_boxart_html()

	print $graph->as_boxart_html();

Return the graph layout as box drawing using Unicode characters,
as chunk that can be embedded into an HTML page.

Basically it wraps the output from L<as_boxart()> into
C<< <pre> </pre> >> and inserts real HTML links. The returned
string is in utf-8.

=head2 as_boxart_html_file()

	print $graph->as_boxart_html_file();

Return the graph layout as box drawing using Unicode characters,
as a full HTML page complete with header and footer.

=head2 as_html()

	print $graph->as_html();

Return the graph layout as HTML section. See L<css()> to get the
CSS section to go with that HTML code. If you want a complete HTML page
then use L<as_html_file()>.

=head2 as_html_page()

	print $graph->as_html_page();

Is an alias for C<as_html_file>.

=head2 as_html_file()

	print $graph->as_html_file();

Return the graph layout as HTML complete with headers, CSS section and
footer. Can be viewed in the browser of your choice.

=head2 add_group()

	my $group = $graph->add_group('Group name');

Add a group to the graph and return it as L<Graph::Easy::Group> object.

=head2 group()

	my $group = $graph->group('Name');

Returns the group with the name C<Name> as L<Graph::Easy::Group> object.

=head2 rename_group()

	$group = $graph->rename_group($group, $new_name);

Changes the name of the given group. If the passed group is not part of
this graph or just a string, it will be added with the new
name to this graph.

If the group was part of another graph, it will be deleted there and added
to this graph with the new name, effectively moving the group from the old
to the new graph and renaming it at the same time.

=head2 groups()

	my @groups = $graph->groups();

Returns the groups of the graph as L<Graph::Easy::Group> objects,
in arbitrary order.
  
=head2 groups_within()

	# equivalent to $graph->groups():
	my @groups = $graph->groups_within();		# all
	my @toplevel_groups = $graph->groups_within(0);	# level 0 only

Return the groups that are inside this graph, up to the specified level,
in arbitrary order.

The default level is -1, indicating no bounds and thus all contained
groups are returned.

A level of 0 means only the direct children, and hence only the toplevel
groups will be returned. A level 1 means the toplevel groups and their
toplevel children, and so on.

=head2 anon_groups()

	my $anon_groups = $graph->anon_groups();

In scalar context, returns the number of anon groups (aka
L<Graph::Easy::Group::Anon>) the graph has.

In list context, returns all anon groups as objects, in arbitrary order.

=head2 del_group()

	$graph->del_group($name);

Delete the group with the given name.

=head2 edges(), edges_within()

	my @edges = $graph->edges();

Returns the edges of the graph as L<Graph::Easy::Edge> objects,
in arbitrary order.

L<edges_within()> is an alias for C<edges()>.

=head2 is_simple_graph(), is_simple()

	if ($graph->is_simple())
	  {
	  }

Returns true if the graph does not have multiedges, e.g. if it
does not have more than one edge going from any node to any other
node or group.

Since this method has to look at all edges, it is costly in terms of
both CPU and memory.

=head2 is_directed()

	if ($graph->is_directed())
	  {
	  }

Returns true if the graph is directed.

=head2 is_undirected()

	if ($graph->is_undirected())
	  {
	  }

Returns true if the graph is undirected.

=head2 parent()

	my $parent = $graph->parent();

Returns the parent graph, for graphs this is undef.

=head2 label()

	my $label = $graph->label();

Returns the label of the graph.

=head2 title()

	my $title = $graph->title();

Returns the (mouseover) title of the graph.

=head2 link()

	my $link = $graph->link();

Return a potential link (for the graphs label), build from the attributes C<linkbase>
and C<link> (or autolink). Returns '' if there is no link.

=head2 as_graphviz()

	print $graph->as_graphviz();

Return the graph as graphviz code, suitable to be feed to a program like
C<dot> etc.

=head2 as_graphviz_file()

	print $graph->as_graphviz_file();

Is an alias for L<as_graphviz()>.

=head2 angle()

        my $degrees = Graph::Easy->angle( 'south' );
        my $degrees = Graph::Easy->angle( 120 );

Check an angle for being valid and return a value between -359 and 359
degrees. The special values C<south>, C<north>, C<west>, C<east>, C<up>
and C<down> are also valid and converted to degrees.

=head2 nodes()

	my $nodes = $graph->nodes();

In scalar context, returns the number of nodes/vertices the graph has.

In list context, returns all nodes as objects, in arbitrary order.

=head2 anon_nodes()

	my $anon_nodes = $graph->anon_nodes();

In scalar context, returns the number of anon nodes (aka
L<Graph::Easy::Node::Anon>) the graph has.

In list context, returns all anon nodes as objects, in arbitrary order.

=head2 html_page_header()

	my $header = $graph->html_page_header();
	my $header = $graph->html_page_header($css);

Return the header of an HTML page. Used together with L<html_page_footer>
by L<as_html_page> to construct a complete HTML page.

Takes an optional parameter with the CSS styles to be inserted into the
header. If C<$css> is not defined, embedds the result of C<< $self->css() >>.

=head2 html_page_footer()

	my $footer = $graph->html_page_footer();

Return the footer of an HTML page. Used together with L<html_page_header>
by L<as_html_page> to construct a complete HTML page.

=head2 css()

	my $css = $graph->css();

Return CSS code for that graph. See L<as_html()>.

=head2 as_txt()

	print $graph->as_txt();

Return the graph as a normalized textual representation, that can be
parsed with L<Graph::Easy::Parser> back to the same graph.

This does not call L<layout()> since the actual text representation
is just a dump of the graph.

=head2 as_txt_file()

	print $graph->as_txt_file();

Is an alias for L<as_txt()>.

=head2 as_svg()

	print $graph->as_svg();

Return the graph as SVG (Scalable Vector Graphics), which can be
embedded into HTML pages. You need to install
L<Graph::Easy::As_svg> first to make this work.

See also L<as_svg_file()>.

B<Note:> You need L<Graph::Easy::As_svg> installed for this to work!

=head2 as_svg_file()

	print $graph->as_svg_file();

Returns SVG just like C<as_svg()>, but this time as standalone SVG,
suitable for storing it in a file and referencing it externally.

After calling C<as_svg_file()> or C<as_svg()>, you can retrieve
some SVG information, notable C<width> and C<height> via
C<svg_information>.

B<Note:> You need L<Graph::Easy::As_svg> installed for this to work!

=head2 svg_information()

	my $info = $graph->svg_information();

	print "Size: $info->{width}, $info->{height}\n";

Return information about the graph created by the last
C<as_svg()> or C<as_svg_file()> call.

The following fields are set:

	width		width of the SVG in pixels
	height		height of the SVG in pixels

B<Note:> You need L<Graph::Easy::As_svg> installed for this to work!

=head2 as_vcg()

	print $graph->as_vcg();

Return the graph as VCG text. VCG is a subset of GDL (Graph Description
Language).

This does not call L<layout()> since the actual text representation
is just a dump of the graph.

=head2 as_vcg_file()

	print $graph->as_vcg_file();

Is an alias for L<as_vcg()>.

=head2 as_gdl()

	print $graph->as_gdl();

Return the graph as GDL (Graph Description Language) text. GDL is a superset
of VCG.

This does not call L<layout()> since the actual text representation
is just a dump of the graph.

=head2 as_gdl_file()

	print $graph->as_gdl_file();

Is an alias for L<as_gdl()>.

=head2 as_graphml()

	print $graph->as_graphml();

Return the graph as a GraphML representation.

This does not call L<layout()> since the actual text representation
is just a dump of the graph.

The output contains only the set attributes, e.g. default attribute values
are not specifically mentioned. The attribute names and values are the
in the format that C<Graph::Easy> defines.

=head2 as_graphml_file()

	print $graph->as_graphml_file();

Is an alias for L<as_graphml()>.

=head2 sorted_nodes()

	my $nodes =
	 $graph->sorted_nodes( );		# default sort on 'id'
	my $nodes = 
	 $graph->sorted_nodes( 'name' );	# sort on 'name'
	my $nodes = 
	 $graph->sorted_nodes( 'layer', 'id' );	# sort on 'layer', then on 'id'

In scalar context, returns the number of nodes/vertices the graph has.
In list context returns a list of all the node objects (as reference),
sorted by their attribute(s) given as arguments. The default is 'id',
e.g. their internal ID number, which amounts more or less to the order
they have been inserted.

This routine will sort the nodes by their group first, so the requested
sort order will be only valid if there are no groups or inside each
group.

=head2 as_debug()

	print $graph->as_debug();

Return debugging information like version numbers of used modules,
and a textual representation of the graph.

This does not call L<layout()> since the actual text representation
is more a dump of the graph, than a certain layout.

=head2 node()

	my $node = $graph->node('node name');

Return node by unique name (case sensitive). Returns undef if the node
does not exist in the graph.

=head2 edge()

	my $edge = $graph->edge( $x, $y );

Returns the edge objects between nodes C<$x> and C<$y>. Both C<$x> and C<$y>
can be either scalars with names or C<Graph::Easy::Node> objects.

Returns undef if the edge does not yet exist.

In list context it will return all edges from C<$x> to C<$y>, in
scalar context it will return only one (arbitrary) edge.

=head2 id()

	my $graph_id = $graph->id();
	$graph->id('123');

Returns the id of the graph. You can also set a new ID with this routine. The
default is ''.

The graph's ID is used to generate unique CSS classes for each graph, in the
case you want to have more than one graph in an HTML page.

=head2 seed()

	my $seed = $graph->seed();
	$graph->seed(2);

Get/set the random seed for the graph object. See L<randomize()>
for a method to set a random seed.

The seed is used to create random numbers for the layouter. For
the same graph, the same seed will always lead to the same layout.

=head2 randomize()

	$graph->randomize();

Set a random seed for the graph object. See L<seed()>.

=head2 debug()

	my $debug = $graph->debug();	# get
	$graph->debug(1);		# enable
	$graph->debug(0);		# disable

Enable, disable or read out the debug status. When the debug status is true,
additional debug messages will be printed on STDERR.

=head2 score()

	my $score = $graph->score();

Returns the score of the graph, or undef if L<layout()> has not yet been called.

Higher scores are better, although you cannot compare scores for different
graphs. The score should only be used to compare different layouts of the same
graph against each other:

	my $max = undef;

	$graph->randomize();
	my $seed = $graph->seed(); 

	$graph->layout();
	$max = $graph->score(); 

	for (1..10)
	  {
	  $graph->randomize();			# select random seed
	  $graph->layout();			# layout with that seed
	  if ($graph->score() > $max)
	    {
	    $max = $graph->score();		# store the new max store
	    $seed = $graph->seed();		# and it's seed
	    }
	  }

	# redo the best layout
	if ($seed ne $graph->seed())
	  {
	  $graph->seed($seed);
	  $graph->layout();
	  }
	# output graph:
	print $graph->as_ascii();		# or as_html() etc

=head2 valid_attribute()

	my $graph = Graph::Easy->new();
	my $new_value =
	  $graph->valid_attribute( $name, $value, $class );

	if (ref($new_value) eq 'ARRAY' && @$new_value == 0)
	  {
	  # throw error
          die ("'$name' is not a valid attribute name for '$class'")
		if $self->{_warn_on_unused_attributes};
	  }
	elsif (!defined $new_value)
	  {
	  # throw error
          die ("'$value' is no valid '$name' for '$class'");
	  }

Deprecated, please use L<validate_attribute()>.

Check that a C<$name,$value> pair is a valid attribute in class C<$class>,
and returns a new value.

It returns an array ref if the attribute name is invalid, and undef if the
value is invalid.

The return value can differ from the passed in value, f.i.:

	print $graph->valid_attribute( 'color', 'red' );

This would print '#ff0000';

=head2 validate_attribute()

	my $graph = Graph::Easy->new();
	my ($rc,$new_name, $new_value) =
	  $graph->validate_attribute( $name, $value, $class );

Checks a given attribute name and value (or values, in case of a
value like "red|green") for being valid. It returns a new
attribute name (in case of "font-color" => "fontcolor") and
either a single new attribute, or a list of attribute values
as array ref.

If C<$rc> is defined, it is the error number:

	1			unknown attribute name
	2			invalid attribute value
	4			found multiple attributes, but these arent
				allowed at this place

=head2 color_as_hex()

	my $hexred   = Graph::Easy->color_as_hex( 'red' );
	my $hexblue  = Graph::Easy->color_as_hex( '#0000ff' );
	my $hexcyan  = Graph::Easy->color_as_hex( '#f0f' );
	my $hexgreen = Graph::Easy->color_as_hex( 'rgb(0,255,0)' );

Takes a valid color name or definition (hex, short hex, or RGB) and returns the
color in hex like C<#ff00ff>.

=head2 color_value($color_name, $color_scheme)

	my $color = Graph::Easy->color_name( 'red' );	# #ff0000
	print Graph::Easy->color_name( '#ff0000' );	# #ff0000

	print Graph::Easy->color_name( 'snow', 'x11' );

Given a color name, returns the color in hex. See L<color_name>
for a list of possible values for the optional C<$color_scheme>
parameter.

=head2 color_name($color_value, $color_scheme)

	my $color = Graph::Easy->color_name( 'red' );	# red
	print Graph::Easy->color_name( '#ff0000' );	# red

	print Graph::Easy->color_name( 'snow', 'x11' );

Takes a hex color value and returns the name of the color.

The optional parameter is the color scheme, where the following
values are possible:

 w3c			(the default)
 x11			(what graphviz uses as default)

Plus the following ColorBrewer schemes are supported, see the
online manual for examples and their usage:

 accent3 accent4 accent5 accent6 accent7 accent8

 blues3 blues4 blues5 blues6 blues7 blues8 blues9

 brbg3 brbg4 brbg5 brbg6 brbg7 brbg8 brbg9 brbg10 brbg11

 bugn3 bugn4 bugn5 bugn6 bugn7 bugn8 bugn9 bupu3 bupu4 bupu5 bupu6 bupu7
 bupu8 bupu9

 dark23 dark24 dark25 dark26 dark27 dark28

 gnbu3 gnbu4 gnbu5 gnbu6 gnbu7 gnbu8 gnbu9

 greens3 greens4 greens5 greens6 greens7 greens8 greens9

 greys3 greys4 greys5 greys6 greys7 greys8 greys9

 oranges3 oranges4 oranges5 oranges6 oranges7 oranges8 oranges9

 orrd3 orrd4 orrd5 orrd6 orrd7 orrd8 orrd9

 paired3 paired4 paired5 paired6 paired7 paired8 paired9 paired10 paired11
 paired12 pastel13 pastel14 pastel15 pastel16 pastel17 pastel18 pastel19

 pastel23 pastel24 pastel25 pastel26 pastel27 pastel28

 piyg3 piyg4 piyg5 piyg6 piyg7 piyg8 piyg9 piyg10 piyg11

 prgn3 prgn4 prgn5 prgn6 prgn7 prgn8 prgn9 prgn10 prgn11

 pubu3 pubu4 pubu5 pubu6 pubu7 pubu8 pubu9

 pubugn3 pubugn4 pubugn5 pubugn6 pubugn7 pubugn8 pubugn9

 puor3 puor4 puor5 puor6 puor7 puor8 puor9 purd3 purd4 purd5 purd6 purd7 purd8
 purd9 puor10 puor11

 purples3 purples4 purples5 purples6 purples7 purples8 purples9

 rdbu10 rdbu11 rdbu3 rdbu4 rdbu5 rdbu6 rdbu7 rdbu8 rdbu9 rdgy3 rdgy4 rdgy5 rdgy6

 rdgy7 rdgy8 rdgy9 rdpu3 rdpu4 rdpu5 rdpu6 rdpu7 rdpu8 rdpu9 rdgy10 rdgy11

 rdylbu3 rdylbu4 rdylbu5 rdylbu6 rdylbu7 rdylbu8 rdylbu9 rdylbu10 rdylbu11

 rdylgn3 rdylgn4 rdylgn5 rdylgn6 rdylgn7 rdylgn8 rdylgn9 rdylgn10 rdylgn11

 reds3 reds4 reds5 reds6 reds7 reds8 reds9

 set13 set14 set15 set16 set17 set18 set19 set23 set24 set25 set26 set27 set28
 set33 set34 set35 set36 set37 set38 set39

 set310 set311 set312

 spectral3 spectral4 spectral5 spectral6 spectral7 spectral8 spectral9
 spectral10spectral11

 ylgn3 ylgn4 ylgn5 ylgn6 ylgn7 ylgn8 ylgn9

 ylgnbu3 ylgnbu4 ylgnbu5 ylgnbu6 ylgnbu7 ylgnbu8 ylgnbu9

 ylorbr3 ylorbr4 ylorbr5 ylorbr6 ylorbr7 ylorbr8 ylorbr9

 ylorrd3 ylorrd4 ylorrd5 ylorrd6 ylorrd7 ylorrd8 ylorrd9

=head2 color_names()

	my $names = Graph::Easy->color_names();

Return a hash with name => value mapping for all known colors.

=head2 text_style()

	if ($graph->text_style('bold, italic'))
	  {
	  ...
	  }

Checks the given style list for being valid.

=head2 text_styles()

	my $styles = $graph->text_styles();	# or $edge->text_styles() etc.

	if ($styles->{'italic'})
	  {
	  print 'is italic\n';
	  }

Return a hash with the given text-style properties, aka 'underline', 'bold' etc.

=head2 text_styles_as_css()

	my $styles = $graph->text_styles_as_css();	# or $edge->...() etc.

Return the text styles as a chunk of CSS styling that can be embedded into
a C< style="" > parameter.

=head2 use_class()

	$graph->use_class('node', 'Graph::Easy::MyNode');

Override the class to be used to constructs objects when calling
C<add_edge()>, C<add_group()> or C<add_node()>.

The first parameter can be one of the following:

	node
	edge
	group

Please see the documentation about C<use_class()> in C<Graph::Easy::Parser>
for examples and details.

=head2 animation_as_graph()

	my $graph_2 = $graph->animation_as_graph();
	print $graph_2->as_ascii();

Returns the animation of C<$graph> as a graph describing the flow of the
animation. Useful for debugging animation flows.

=head2 add_cycle()

	$graph->add_cycle('A','B','C');		# A -> B -> C -> A

Compatibility method for Graph, adds the edges between each node
and back from the last node to the first. Returns the graph.

=head2 add_path()

	$graph->add_path('A','B','C');		# A -> B -> C

Compatibility method for Graph, adds the edges between each node.
Returns the graph.

=head2 add_vertex()

	$graph->add_vertex('A');

Compatibility method for Graph, adds the node and returns the graph.

=head2 add_vertices()

	$graph->add_vertices('A','B');

Compatibility method for Graph, adds these nodes and returns the graph.

=head2 has_edge()

	$graph->has_edge('A','B');

Compatibility method for Graph, returns true if at least one edge between
A and B exists.

=head2 vertices()

Compatibility method for Graph, returns in scalar context the number
of nodes this graph has, in list context a (arbitrarily sorted) list
of node objects.

=head2 set_vertex_attribute()

	$graph->set_vertex_attribute( 'A', 'fill', '#deadff' );

Compatibility method for Graph, set the named vertex attribute.

Please note that this routine will only accept Graph::Easy attribute
names and values. If you want to attach custom attributes, you need to
start their name with 'x-':

	$graph->set_vertex_attribute( 'A', 'x-foo', 'bar' );

=head2 get_vertex_attribute()

	my $fill = $graph->get_vertex_attribute( 'A', 'fill' );

Compatibility method for Graph, get the named vertex attribute.

Please note that this routine will only accept Graph::Easy attribute
names. See L<set_vertex_attribute()>.

=head1 EXPORT

Exports nothing.

=head1 SEE ALSO

L<Graph>, L<Graph::Convert>, L<Graph::Easy::As_svg>, L<Graph::Easy::Manual> and
L<Graph::Easy::Parser>.

=head2 Related Projects

L<Graph::Layout::Aesthetic>, L<Graph> and L<Text::Flowchart>.

There is also an very old, unrelated project from ca. 1995, which does something similar.
See L<http://rw4.cs.uni-sb.de/users/sander/html/gsvcg1.html>.

Testcases and more examples under:

L<http://bloodgate.com/perl/graph/>.

=head1 LIMITATIONS

This module is now quite complete, but there are still some limitations.
Hopefully further development will lift these.

=head2 Scoring

Scoring is not yet implemented, each generated graph will be the same regardless
of the random seed.

=head2 Layouter

The layouter can not yet handle links between groups (or between
a group and a node, or vice versa). These links will thus only
appear in L<as_graphviz()> or L<as_txt()> output.

=head2 Paths

=over 2

=item No optimizations

In complex graphs, non-optimal layout part like this one might appear:

	+------+     +--------+
	| Bonn | --> | Berlin | --> ...
	+------+     +--------+
	               ^
	               |
	               |
	+---------+    |
	| Kassel  | ---+
	+---------+

A second-stage optimizer that simplifies these layouts is not yet implemented.

In addition the general placement/processing strategy as well as the local
strategy might be improved.

=item attributes

The following attributes are currently ignored by the layouter:

	undirected graphs
	autosplit/autojoin for edges
	tail/head label/title/link for edges

=item groups

The layouter is not fully recursive yet, so groups do not properly nest.

In addition, links to/from groups are missing, too.

=back

=head2 Output formats

Some output formats are not yet complete in their
implementation. Please see the online manual at
L<http://bloodgate.com/perl/graph/manual> under "Output" for
details.

X<graph>
X<manual>
X<online>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL 2.0 or a later version.

See the LICENSE file for a copy of the GPL.

This product includes color specifications and designs developed by Cynthia
Brewer (http://colorbrewer.org/). See the LICENSE file for the full license
text that applies to these color schemes.

X<gpl>
X<apache-style>
X<cynthia>
X<brewer>
X<colorscheme>
X<license>

=head1 NAME CHANGE

The package was formerly known as C<Graph::Simple>. The name was changed
for two reasons:

=over 2

=item *

In graph theory, a C<simple> graph is a special type of graph. This software,
however, supports more than simple graphs.

=item *

Creating graphs should be easy even when the graphs are quite complex.

=back

=head1 AUTHOR

Copyright (C) 2004 - 2008 by Tels L<http://bloodgate.com>

X<tels>

=cut
1;
