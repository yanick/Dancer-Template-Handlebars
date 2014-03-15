package Dancer::Template::Handlebars;
BEGIN {
  $Dancer::Template::Handlebars::AUTHORITY = 'cpan:YANICK';
}
# ABSTRACT: Wrapper for the Handlebars template system
$Dancer::Template::Handlebars::VERSION = '0.2.0';

use strict;
use warnings;

use Dancer::Config 'setting';

use Text::Handlebars;

use Moo;
extends 'Dancer::Template::Abstract';

has views_root => (
    is => 'ro',
    lazy => 1,
    default => sub {
        Dancer::App->current->setting('views')
    },
);

has helpers => (
    is => 'ro',
    lazy => 1,
    default => sub { {} },
);

has _engine => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        
        return Text::Handlebars->new(
            path => [
                $self->views_root
            ],
            helpers => $self->helpers,
            %{ $self->config },
        );
    },
);

sub BUILD {
    my $self = shift;
    
    if ( my $h = delete $self->config->{helpers} ) {
        $self->gather_helpers($h);
    }
}

sub gather_helpers {
    my( $self, $modules ) = @_;

    for my $module ( ref $modules ? @$modules : $modules ) {
        my %helpers = eval "use $module; %".$module.'::HANDLEBARS_HELPERS';
        while( my ($k,$v) = each %helpers ) {
            $self->helpers->{$k} = $v;
        }
    }
}


sub default_tmpl_ext { "hbs" }

sub view {
    my ($self, $view) = @_;

    return $view if ref $view;

    for my $view_path ($self->_template_name($view)) {
        return $view_path if -f join '/', $self->views_root, $view_path;
    }

    # No matching view path was found
    return;
}

sub layout {
    my ($self, $layout, $tokens, $content) = @_;

    my $dir = Dancer::App->current->setting('views');
    my( $layout_name ) = grep { -e join '/', $dir, $_ }
                          map { 'layouts/'.$_ } $self->_template_name($layout);

    my $full_content;
    if (-e join '/', $dir, $layout_name ) {
        $full_content = Dancer::Template->engine->render(
                                     $layout_name, {%$tokens, content => $content});
    } else {
        $full_content = $content;
        Dancer::Logger::error("Defined layout ($layout) was not found!");
    }
    $full_content;
}

sub view_exists { 
    my( $self, $template) = @_;

    # string ref or file
    return ref($template) || -f join '/', $self->views_root, $template;

}

sub render {
    my ($self, $template, $tokens) = @_;

    if ( ref $template ) {
        return $self->_engine->render_string( $$template, $tokens );
    }

    return $self->_engine->render( $template, $tokens );

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Template::Handlebars - Wrapper for the Handlebars template system

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

    # in config.yml
   template: handlebars

   engines:
        handlebars:
            helper_modules:
                - MyApp::HandlebarsHelpers

   # in the app
   get '/style/:style' => sub {
       template 'style' => {
           style => param('style')
       };
   };

   # in views/style.mustache
   That's a nice, manly {{style}} mustache you have there!

=head1 DESCRIPTION

Wrapper for L<Text::Handlebars>, the Perl implementation of the Handlebars
templating system.

=head2 Configuration

The arguments passed to the 'handlebars' engine are given directly to the
L<Text::Handlebars> constructor, 
with the exception of C<helper_modules> (see below for details).

=head2 Calls to 'template()'

When calling C<template>, one can use a filename as usual, or can pass a 
string reference, which will treated as the template itself.

    get '/file' => sub {
        # look for the file views/my_template.hbs
        template 'my_template', {
            name => 'Bob',
        };
    };

    get '/string' => sub {
        # provide the template directly
        template \'hello there {{name}}', {
            name => 'Bob',
        };
    };

The default extension for Handlebars templates is 'C<hbs>'.

=head2 Helper Functions

Handlebars helper functions can be defined in modules, which are
passed via C<helper_modules> in the configuration. See
L<Dancer::Template::Handlebars::Helpers> for more details on how to register
the functions themselves.

=head2 Layouts

Layouts are supported. The content of the inner template will
be available via the 'content' variable. 

Example of a perfectly valid, if slightly boring, layout:

    <html>
    <body>
        {{ content }}
    </body>
    </html>

=head1 SEE ALSO

=over

=item L<Dancer::Template::Mustache> - similar Dancer wrapper for L<Template::Mustache>.

=back

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
