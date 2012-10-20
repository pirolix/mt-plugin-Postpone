package MT::Plugin::OMV::Postpone;
# $Id$

use strict;
use MT 3;
use MT::Template::Context;
use MT::Builder;

use vars qw( $VENDOR $MYNAME $VERSION );
($VENDOR, $MYNAME) = (split /::/, __PACKAGE__)[-2, -1];
(my $revision = '$Rev$') =~ s/\D//g;
$VERSION = '0.01'. ($revision ? ".$revision" : '');

use base qw( MT::Plugin );
my $plugin = __PACKAGE__->new({
    name => $MYNAME,
    id => lc $MYNAME,
    key => lc $MYNAME,
    version => $VERSION,
    author_name => 'Open MagicVox.net',
    author_link => 'http://www.magicvox.net/',
#    doc_link => '',
    description => <<PERLHEREDOC,
Postpone building templates after build it
PERLHEREDOC
#    l10n_class => $MYNAME. '::L10N',
});
MT->add_plugin ($plugin);

###
my %tags = (
    '<' => "<!-- ${MYNAME}_Start_Bracket -->",
    '>' => "<!-- ${MYNAME}_Close_Bracket -->",
);

### Block tag
MT::Template::Context->add_container_tag ($MYNAME => sub {
    my ($ctx, $args, $cond) = @_;

    my $uncompiled = $ctx->stash ('uncompiled');
    # Escape Tag's brackets
    my $pattern = join '|', keys %tags;
    $uncompiled =~ s/($pattern)/$tags{$1}/eg;
    $uncompiled;
});

### Postponed building
MT->add_callback ('BuildPage', 9, $plugin, sub {
    my ($eh, %opt) = @_;
    my $ctx = $opt{Context};
    my $out = $opt{Content};

    # Unescape Tag's brackets
    while (my ($k, $v) = each %tags) {
        $$out =~ s/\Q$v\E/$k/g;
    }
    # Re-Build
    my $builder = MT::Builder->new;
    my $tokens = $builder->compile ($ctx, $$out)
        or return $eh->error ($builder->errstr);
    defined ($$out = $builder->build ($ctx, $tokens, {}))
        or return $eh->error ($ctx->errstr);
});

1;