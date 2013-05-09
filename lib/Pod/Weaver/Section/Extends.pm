package Pod::Weaver::Section::Extends;
# ABSTRACT: Add a list of parent classes to your POD.

use strict;
use warnings;
use Module::Load;
use Moose;
with 'Pod::Weaver::Role::Section';

use aliased 'Pod::Elemental::Element::Nested';
use aliased 'Pod::Elemental::Element::Pod5::Command';
my @ORIG_INC = @INC;

sub weave_section { 
    my ( $self, $doc, $input ) = @_;

    my $filename = $input->{filename};
    #extend section is written only for lib/*.pm and for one package pro file
    return if $filename !~ m{^lib};
    return if $filename !~ m{\.pm$};

    my $module = $filename;
    $module =~ s{^lib/}{}; #will there be a backslash on win32?
    $module =~ s{/}{::}g;
    $module =~ s{\.pm$}{};
    #print "module:$module\n";
    unshift @INC, './lib';
    eval { load $module };    #use full path for require
    @INC = @ORIG_INC;
    print $@ if $@;

    my @parents = $self->_get_parents( $module );        

    return unless @parents;

    my @pod = (
        Command->new( { 
            command   => 'over',
            content   => 4
        } ),

        ( map { 
            Command->new( {
                command    => 'item',
                content    => sprintf '* L<%s>', $_
            } ),
        } @parents ),
        Command->new( { 
            command   => 'back',
            content   => ''
        } )
    );        

    push @{ $doc->children },
        Nested->new( { 
            type      => 'command',
            command   => 'head1',
            content   => 'EXTENDS',
            children  => \@pod
        } );

}

sub _get_parents { 
    my ( $self, $module ) = @_;

    no strict 'refs';
    return @{ $module . '::ISA' };
}

__PACKAGE__->meta->make_immutable;
1;


=pod

=head1 SYNOPSIS

In your C<weaver.ini>:

    [Extends]

=head1 DESCRIPTION

This L<Pod::Weaver> section plugin creates an "EXTENDS" section in your POD
which will contain a list of your class's parent classes. It accomplishes
this by attempting to compile your class and inspecting its C<@ISA>. 

