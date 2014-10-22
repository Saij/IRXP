package IRXP::Modules;

use strict;
use warnings;

use Carp;
use Class::Load ':all';

use IRXP::LexWrap;
use IRXP::Utils;

sub new {
    my ($class, %options) = @_;

    my $data = {overwrite => {}};

    my $self = bless $data, $class;

    return $self;
}

sub init_overwrites {
    my ($self, %options) = @_;

    foreach my $module (keys %{ $self->{overwrite} }) {
        IRXP::Log->log(message => "Overwriting Subs in Module $module...", type => IRXP::Log::LOG_TYPE_INFO);
        load_class($module);

        foreach my $sub (keys %{ $self->{overwrite}->{$module} }) {
            if (defined $self->{overwrite}->{$module}->{$sub}->{pre} && defined $self->{overwrite}->{$module}->{$sub}->{post}) {
                wrap $module . '::' . $sub, pre => $self->{overwrite}->{$module}->{$sub}->{pre}, post => $self->{overwrite}->{$module}->{$sub}->{post};
                IRXP::Log->log(message => "\tOverwritten " . $module . '::' . $sub . ' with pre and post sub.', type => IRXP::Log::LOG_TYPE_INFO);
            }
            elsif (defined $self->{overwrite}->{$module}->{$sub}->{pre}) {
                wrap $module . '::' . $sub, pre => $self->{overwrite}->{$module}->{$sub}->{pre};
                IRXP::Log->log(message => "\tOverwritten " . $module . '::' . $sub . ' with pre sub.', type => IRXP::Log::LOG_TYPE_INFO);
            }
            elsif (defined $self->{overwrite}->{$module}->{$sub}->{post}) {
                wrap $module . '::' . $sub, post => $self->{overwrite}->{$module}->{$sub}->{post};
                IRXP::Log->log(message => "\tOverwritten " . $module . '::' . $sub . ' with post sub.', type => IRXP::Log::LOG_TYPE_INFO);
            }
            elsif (defined $self->{overwrite}->{$module}->{$sub}->{replace}) {
                replace_sub $module . '::' . $sub, replace => $self->{overwrite}->{$module}->{$sub}->{replace};
                IRXP::Log->log(message => "\tReplaced " . $module . '::' . $sub . ' with sub.', type => IRXP::Log::LOG_TYPE_INFO);                
            } 
            else {
                confess 'No overwriting material defined!';
            }
        }
    }
}

sub is_correct_version {
    confess 'Not implemented!';
}

sub inject_params {
    my ($self, $template_file, $object, $tmpl_params) = @_;

    return if (!defined $self->{templates}->{$template_file});
    return if (!defined $self->{templates}->{$template_file}->{params});

    &{$self->{templates}->{$template_file}->{params}}($self, $object, $tmpl_params);
}

sub inject_template {
    my ($self, $template_file, $params) = @_;

    return undef if (!defined $self->{templates}->{$template_file});
    return undef if (!defined $self->{templates}->{$template_file}->{file});

    my $template = get_file($self->{templates}->{$template_file}->{file});

    foreach my $injector (@{ $self->{templates}->{$template_file}->{injectors} }) {
        my $injected = '';

        if (defined $injector->{file}) {
            $injected = get_file(basedir() . '/templates/' . $injector->{file});
        }

        $injector->{replacer}($template, $injected);
    }

    return \$template;
}

1;