### //////////////////////////////////////////////////////////////////////////
#
#	TOP
#

=head1 NAME

DynaPage::Document::ext::include - 'include' extension of DynaPag::Document

 #------------------------------------------------------
 # (C) Daniel Peder & Infoset s.r.o., all rights reserved
 # http://www.infoset.com, Daniel.Peder@infoset.com
 #------------------------------------------------------

=cut

###													###
###	size of <TAB> in this document is 4 characters	###
###													###

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: package
#

    package DynaPage::Document::ext::include;


### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: version
#

	use vars qw( $VERSION $VERSION_LABEL $REVISION $REVISION_DATETIME $REVISION_LABEL $PROG_LABEL );

	$VERSION           = '0.10';
	
	$REVISION          = (qw$Revision: 1.2 $)[1];
	$REVISION_DATETIME = join(' ',(qw$Date: 2005/01/13 22:20:53 $)[1,2]);
	$REVISION_LABEL    = '$Id: include.pm,v 1.2 2005/01/13 22:20:53 root Exp $';
	$VERSION_LABEL     = "$VERSION (rev. $REVISION $REVISION_DATETIME)";
	$PROG_LABEL        = __PACKAGE__." - ver. $VERSION_LABEL";

=pod

 $Revision: 1.2 $
 $Date: 2005/01/13 22:20:53 $

=cut


### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: debug
#

	# use vars qw( $DEBUG ); $DEBUG=0;
	

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: constants
#

	# use constant	name		=> 'value';
	

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: modules use
#

	require 5.005_62;

	use strict                  ;
	use warnings                ;
	
	use	DynaPage::Sourcer		;
	use	DynaPage::Template		;
	use	IO::File::String		;
	use	File::Spec				;
	

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: class properties
#

#	our	$config	= 
#	{
#	};
	

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: methods
#

=head1 METHODS

=over 4

=cut



# ### //////////////////////////////////////////////////////////////////////////
#
# =item	PLUG ( $Doc, $job ) : bool
#
# Plug-in extension.
#
# =cut
#
# ### --------------------------------------------------------------------------
# sub		PLUG {
# ### --------------------------------------------------------------------------
#        my( $Doc, $job ) = @_;
# }


### //////////////////////////////////////////////////////////////////////////

=item	template ( $self, $job ) : bool

 syntax:
 !include.template =- B<file_name>
 
See also DynaPage::Template

B<NOTE:> $self is parent document object (eg blessed into DynaPage::Document)

=cut

### --------------------------------------------------------------------------
sub	template {
### --------------------------------------------------------------------------
    my( $self, $job ) = @_;
       
    # my( $type, $type_ext ) = $job->[0] =~ m/^!\w+\.(\w+)(?:\.(\w+))?/;
    my  $param = $job->[1];
    my	$data	= $self->Read( $param );
		$self->Template( $data ) if $data;
	
    return 1;
       
}


### //////////////////////////////////////////////////////////////////////////

=item	data ( $self, $job ) : bool

 syntax:
 !include.data =- B<file_name>
 
Parse data read from B<file_name> results are merged into parent document.
If data contained another !include or other extension commands, they will
be handled properly. Parsing is done by DynaPage::Sourcer Parse() method.

B<NOTE:> $self is parent document object (eg blessed into DynaPage::Document)

=cut

### --------------------------------------------------------------------------
sub	data {
### --------------------------------------------------------------------------
    my( $self, $job ) = @_;
       
    #my( $type, $type_ext ) = $job->[0] =~ m/^!\w+\.(\w+)(?:\.(\w+))?/;
    my  $param = $job->[1];
	my	$data	= $self->Read( $param );
		$self->Sourcer->Parse( $data ) if $data;
	
    return 1;
       
}


### //////////////////////////////////////////////////////////////////////////

=item	field ( $self, $job ) : bool

 syntax-1:
 !include.field.B<target-field> =- B<file_name>

 syntax-2:
 !include.field =- B<target-field> B<file_name>

Set B<target-field> to contain data read from 
external file specified by B<file_name>.

B<NOTE:> $self is parent document object (eg blessed into DynaPage::Document)

=cut

### --------------------------------------------------------------------------
sub	field {
### --------------------------------------------------------------------------
    my( $self, $job ) = @_;
       
    my( $type, $type_ext ) = $job->[0] =~ m/^!\w+\.(\w+)(?:\.(\w+))?/;
    #my  $param = $job->[1];
    my  @param = split('\s+',$job->[1]);
 	my  $target_field  = $type_ext || shift(@param);
	my	$data	= $self->Read( $param[0] );
	if( $data ) {
        $target_field =~ s{.*/([^/]+)$}{$1}s; # drop dir prefix
        $target_field =~ s{[^\w\-\.]+}{_}gos; # convert invalid chars
 		$self->Sourcer->Set( $target_field => $data );
	}
	
    return 1;
       
}


### //////////////////////////////////////////////////////////////////////////

=item	hooks ( $self, $job ) : bool

 syntax-1:
 !include.hooks ==~
   Init => sub {
     my( $self, $hook_name, $hook_params ) =@_;
     ...
     ... PERL SCRIPT CODE
     ...
   }
 ~== !include.hooks

B<NOTE:> $self is parent document object (eg blessed into DynaPage::Document)

=cut

### --------------------------------------------------------------------------
sub	handlers { hooks(@_) } # just for backward compatibiliy
### --------------------------------------------------------------------------
sub	hooks {
### --------------------------------------------------------------------------
    my( $self, $job ) = @_;
    
    return 0 unless $self->{OPTIONS}{HooksEnable};
       
    my( $type, $type_ext ) = $job->[0] =~ m/^!\w+\.(\w+)(?:\.(\w+))?/;
    # my  $param = $job->[1];
	# my  $hooks = eval( '{' .$param . '}' );
	my  $hooks = eval( '{'.$job->[1].'}' );
	if( $hooks && ref($hooks) eq 'HASH' )
	{
		for my $key ( keys %$hooks )
		{
			my $hook = $hooks->{$key};
			unless( ref($hook) eq 'CODE' )
			{
				warn "ERR[include.$type]: '$key' isn't CODE reference";
			}
			
			$self->{HOOK}{$key} = $hook;
		}
	}
	elsif( $@ )
	{
		warn "ERR[include.$type]: $@";
	}
	else
	{
		warn "ERR[include.$type]: missing correct hook definitions";
	}
	
    return 1;
       
}


### //////////////////////////////////////////////////////////////////////////

=item	module ( $self, $job ) : bool

B<NOTE:> $self is parent document object (eg blessed into DynaPage::Document)

=cut

### --------------------------------------------------------------------------
sub	module {
### --------------------------------------------------------------------------
    my( $self, $job ) = @_;
       
    my( $type, $type_ext ) = $job->[0] =~ m/^!\w+\.(\w+)(?:\.(\w+))?/;
    my $param = $job->[1];
	my @modules = grep {$_} split( '[\r\n]+', $param );
	# push @{ $self->{MODULE} }, @modules;
	for my $module ( @modules )
	{
		eval ( 'use '.$module.' ;' );
		if($@)
		{
			$self->{MODULE}{$module} = '0_ERR:'.$@;
			warn "ERR[include.$type $module]: $@";
		}
		else
		{
			$self->{MODULE}{$module} = '1_OK';
		}
	}
	
    return 1;
       
}


### //////////////////////////////////////////////////////////////////////////

=item	parameters ( $self, $job ) : bool

B<NOTE:> $self is parent document object (eg blessed into DynaPage::Document)

=cut

### --------------------------------------------------------------------------
sub	parameters {
### --------------------------------------------------------------------------
    my( $self, $job ) = @_;
       
    #my( $type, $type_ext ) = $job->[0] =~ m/^!\w+\.(\w+)(?:\.(\w+))?/;
    my $param = $job->[1];
	
	$param  =~ s/.*?a.*/pgceh/os unless
	$param  =~ s/.*?A.*/PGCEH/os
    ;

	my $cgi;
    if( defined( &CGI::new )) {
        $cgi = CGI->new();   
    }
    # check CGI & HTTP params handling
    $param =~ s{[pg]}{}igos unless defined $cgi;
    $param =~ s{[pgch]}{}igos unless $ENV{REQUEST_METHOD};

	while( $param =~ m{([PGCEH])}icgos )
    {        
        my  $param_key = $1;
        my  $prefix = (uc($param_key) eq $param_key) ? $param_key.'_' : '';
            $param_key = uc($param_key);
            
        if(     $param_key eq 'P' and $cgi->request_method() eq 'POST' ) { # POST
            my @names = $cgi->param();
            if(@names){
            $self->Sourcer->Add( $prefix.'_NAMES' => join(',',@names) );
            for(my $i=0; $i<=$#names; $i++ )
            {
                my  $parn = $names[$i];
                my  $name = $prefix.$parn;
                my  @vals = $cgi->param( $parn );
                for my $val (@vals) {
                    $self->Sourcer->Add( $name => $val );
                }
            }
            }
        } 
        elsif(  $param_key eq 'G' ) { # GET
            my @names = $cgi->url_param();
            if(@names){
            $self->Sourcer->Add( $prefix.'_NAMES' => join(',',@names) );
            for(my $i=0; $i<=$#names; $i++ )
            {
                my  $parn = $names[$i];
                my  $name = $prefix.$parn;
                my  @vals = $cgi->url_param( $parn );
                for my $val (@vals) {
                    $self->Sourcer->Add( $name => $val );
                }
            }
            }
        } 
        elsif(  $param_key eq 'C' ) { # COOKIE
            my %cookies = CGI::Cookie->fetch();
            for my $key ( keys %cookies )
            {
                my $name = $prefix.$key;
                $self->Sourcer->Add( $name => $cookies{$key}->value() );
            }
        } 
        elsif(  $param_key eq 'E' ) { # ENVIRONMENT
            for my $key ( keys %ENV )
            {
                my $name = $prefix.$key;
                $self->Sourcer->Add( $name => $ENV{$key} );
            }
        } 
    }

    return 1;
       
}

=back

=cut


1;

__DATA__

__END__

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: TODO
#


=head1 TODO	

=cut
