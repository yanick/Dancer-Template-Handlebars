package Dancer::Template::Handlebars::Helpers;
# ABSTRACT: parent class for Handlebars' helper collections


use strict;
use warnings;

use Sub::Attribute;

sub Helper :ATTR_SUB {
    my( $class, $sym_ref, $code_ref, $attr_name, $attr_data ) = @_;

    my $fname = *{ $sym_ref }{NAME};
    my $helper_name = $attr_data || *{ $sym_ref }{NAME};

    eval qq{
        package $class;
        \$${class}::HANDLEBARS_HELPERS{$helper_name} = \\\&$fname;
    } or die $@;
}

1;

__END__

=head1 SYNOPSIS

    package MyApp::HandlebarsHelpers;

    use parent Dancer::Template::Handlebars::Helpers;

    sub shout :Helper {
        my( $context, $text ) = @_;
        return uc $text;
    }

    sub internal_name :Helper(whisper) {
        my( $context, $text ) = @_;
        return lc $text;
    }

    1;

and then in the Dancer app config.yml:

    engines:
        handlebars:
            helpers:
                - MyApp::HandlebarsHelpers

=head1 DESCRIPTION

Base class for modules containing Handlebars helper functions.
The helper functions are labelled with the C<:Helper> attribute.
A name for the helper function can be passed or, if not, will default
to the sub's name.

Behind the curtain, what the attribute does is to add the 
tagged functions to a module-wide C<%HANDLEBARS_HELPERS> variable,
which has the function names as keys and their coderefs as values.
For example, to register the functions of the SYNOPSIS
without the help of C<Dancer::Template::Handlebars::Helpers>, one could do:

    package MyApp::HandlebarsHelpers;

    our HANDLEBARS_HELPERS = (
        shout   => \&shout,
        whisper => \&internal_name,
    );

    sub shout {
        my( $context, $text ) = @_;
        return uc $text;
    }

    sub internal_name {
        my( $context, $text ) = @_;
        return lc $text;
    }

    1;




=end
