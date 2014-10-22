package IRXP::LexWrap;

use strict;
use warnings;

use Carp;

{
    no warnings 'redefine';
    *CORE::GLOBAL::caller = sub (;$) {
        my ($height) = ($_[0] || 0);
        my $i = 1;
        my $name_cache;
        while (1) {
            my @caller = CORE::caller($i++) or return;
            $caller[3] = $name_cache if ($name_cache);
            $name_cache = $caller[0] eq 'IRXP::LexWrap' ? $caller[3] : '';
            next if ($name_cache || $height-- != 0);
            return wantarray ? @_ ? @caller : @caller[0..2] : $caller[0];
        }
    };
}

sub import { 
    no strict 'refs'; 
    *{caller()."::wrap"} = \&wrap;
    *{caller()."::replace_sub"} = \&replace_sub;
}

sub replace_sub (*@) {
    my ($typeglob, %wrapper) = @_;
    $typeglob = (ref $typeglob || $typeglob =~ /::/) ? $typeglob : caller()."::$typeglob";
    croak "'sub' value is not a subroutine reference" if ref ($wrapper{replace} ne 'CODE');

    {
        no strict 'refs';
        *{$typeglob} = $wrapper{replace};
    }
}

sub wrap (*@) {  ## no critic Prototypes
    my ($typeglob, %wrapper) = @_;
    $typeglob = (ref $typeglob || $typeglob =~ /::/) ? $typeglob : caller()."::$typeglob";
    my $original;
    {
        no strict 'refs';
        $original = ref $typeglob eq 'CODE' && $typeglob || *$typeglob{CODE} || croak 'Can\'t wrap non-existent subroutine ', $typeglob;
    }
    croak "'$_' value is not a subroutine reference" foreach grep {$wrapper{$_} && ref $wrapper{$_} ne 'CODE'} qw(pre post);
    no warnings 'redefine';
    my ($caller, $unwrap) = *CORE::GLOBAL::caller{CODE};
    my $imposter = sub {
        goto &$original if ($unwrap);
        my ($return, $prereturn, @newparams);
        my $paramsub = bless sub { @newparams = @_ }, 'IRXP::LexWrap::Cleanup';

        if (wantarray) {
            $prereturn = $return = [];
            () = $wrapper{pre}->(@_, $paramsub, $return) if $wrapper{pre};
            @_ = @newparams if (@newparams);
            my @curparams = @_;
            if (ref $return eq 'ARRAY' && $return == $prereturn && !@$return) {
                $return = [ &$original ];
                () = $wrapper{post}->(@curparams, $return) if $wrapper{post};
            }
            return ref $return eq 'ARRAY' ? @$return : ($return);
        }
        elsif (defined wantarray) {
            $return = bless sub { $prereturn = 1 }, 'IRXP::LexWrap::Cleanup';
            my $dummy = $wrapper{pre}->(@_, $paramsub, $return) if $wrapper{pre};
            @_ = @newparams if (@newparams);
            my @curparams = @_;
            unless ($prereturn) {
                $return = &$original;
                $dummy = scalar $wrapper{post}->(@curparams, $return) if $wrapper{post};
            }
            return $return;
        }
        else {
            $return = bless sub { $prereturn = 1 }, 'IRXP::LexWrap::Cleanup';
            $wrapper{pre}->(@_, $paramsub, $return) if $wrapper{pre};
            @_ = @newparams if (@newparams);
            my @curparams = @_;
            unless ($prereturn) {
                &$original;
                $wrapper{post}->(@curparams, $return) if $wrapper{post};
            }
            return;
        }
    };
    ref $typeglob eq 'CODE' and return defined wantarray ? $imposter : carp "Uselessly wrapped subroutine reference in void context";
    {
            no strict 'refs';
            *{$typeglob} = $imposter;
    }
    return unless defined wantarray;
    return bless sub{ $unwrap = 1 }, 'IRXP::LexWrap::Cleanup';
}

package IRXP::LexWrap::Cleanup;

sub DESTROY { $_[0]->() }
use overload 
    q{""}   => sub { undef },
    q{0+}   => sub { undef },
    q{bool} => sub { undef },
    q{fallback}=>1; #fallback=1 - like no overloading for other operations

1;