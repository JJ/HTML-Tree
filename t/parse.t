#!/usr/bin/perl -T

use warnings;
use strict;
use Test::More;
my $DEBUG = 2;
BEGIN { plan tests => 44 }

use HTML::TreeBuilder;
use HTML::Element;

print "#Using HTML::TreeBuilder version v$HTML::TreeBuilder::VERSION\n";
print "#Using HTML::Element version v$HTML::Element::VERSION\n";
print "#Using HTML::Parser version v", $HTML::Parser::VERSION || "?", "\n";
print "#Using HTML::Entities version v", $HTML::Entities::VERSION || "?",
    "\n";
print "#Using HTML::Tagset version v", $HTML::Tagset::VERSION || "?", "\n";
print "# Running under perl version $] for $^O",
    ( chr(65) eq 'A' ) ? "\n" : " in a non-ASCII world\n";
print "# Win32::BuildNumber ", &Win32::BuildNumber(), "\n"
    if defined(&Win32::BuildNumber)
        and defined &Win32::BuildNumber();
print "# MacPerl verison $MacPerl::Version\n"
    if defined $MacPerl::Version;
printf
    "# Current time local: %s\n# Current time GMT:   %s\n",
    scalar( localtime($^T) ), scalar( gmtime($^T) );

ok 1;

{
    my $tree = HTML::TreeBuilder->new;
    $tree->parse('<title>foo</title><p>I like pie');
    $tree->eof;
    ok( $tree->as_XML,
              "<html><head><title>foo</title></head><body>"
            . "<p>I like pie</p></body></html>\n" );
    $tree->delete;
}

ok !same( 'x'   => 'y', 1 );
ok !same( '<p>' => 'y', 1 );

ok same( '' => '' );
ok same( '' => ' ' );
ok same( '' => '  ' );

ok same( '' => '<!-- tra la la -->' );
ok same( '' => '<!-- tra la la --><!-- foo -->' );

ok same( '' => \'<head></head><body></body>' );

ok same( '<head>' => '' );

ok same( '<head></head><body>' => \'<head></head><body></body>' );

ok same( '<img alt="456" src="123">' => '<img src="123" alt="456">' );
ok same( '<img alt="456" src="123">' => '<img src="123"    alt="456">' );
ok same( '<img alt="456" src="123">' => '<img src="123"    alt="456"   >' );

ok !same( '<img alt="456" >' => '<img src="123"    alt="456"   >', 1 );

ok same( 'abc&#32;xyz'  => 'abc xyz' );
ok same( 'abc&#x20;xyz' => 'abc xyz' );

ok same( 'abc&#43;xyz'  => 'abc+xyz' );
ok same( 'abc&#x2b;xyz' => 'abc+xyz' );

ok same( '&#97;bc+xyz'  => 'abc+xyz' );
ok same( '&#x61;bc+xyz' => 'abc+xyz' );

print "#\n# Now some list tests.\n#\n";

ok same( '<ul><li>x</ul>after'      => '<ul><li>x</li></ul>after' );
ok same( '<ul><li>x<li>y</ul>after' => '<ul><li>x</li><li>y</li></ul>after' );

ok same( '<ul> <li>x</li> <li>y</li> </ul>after' =>
        '<ul><li>x</li><li>y</li></ul>after' );

ok same( '<ul><li>x<li>y</ul>after' => \
        '<head></head><body><ul><li>x</li><li>y</li></ul>after</body>' );

print "#\n# Now some table tests.\n#\n";

ok same( '<table>x<td>y<td>z' =>
        '<table><tr><td>x</td><td>y</td><td>z</td></table>' );

ok same( '<table>x<td>y<tr>z' =>
        '<table><tr><td>x</td><td>y</td></tr><tr><td>z</td></tr></table>' );

ok same( '<table><tr><td>x</td><td>y</td></tr><tr><td>z</td></tr></table>' =>
        '<table><tr><td>x</td><td>y</td></tr><tr><td>z</td></tr></table>' );
ok same(
    '<table><tr><td>x</td><td>y</td></tr><tr><td>z</td></tr></table>' => \
        '<head></head><body><table><tr><td>x</td><td>y</td></tr><tr><td>z</td></tr></table>'
);

ok same( '<table>x' => '<td>x' );
ok same( '<table>x' => '<table><td>x' );
ok same( '<table>x' => '<tr>x' );
ok same( '<table>x' => '<tr><td>x' );
ok same( '<table>x' => '<table><tr>x' );
ok same( '<table>x' => '<table><tr><td>x' );

print "#\n# Now some p tests.\n#\n";

ok same( '<p>x<p>y<p>z' => '<p>x</p><p>y</p><p>z' );
ok same( '<p>x<p>y<p>z' => '<p>x</p><p>y<p>z</p>' );
ok same( '<p>x<p>y<p>z' => '<p>x</p><p>y</p><p>z</p>' );
ok same( '<p>x<p>y<p>z' => \'<head></head><body><p>x</p><p>y</p><p>z</p>' );

sub same {
    my ( $code1, $code2, $flip ) = @_;
    my $t1 = HTML::TreeBuilder->new;
    my $t2 = HTML::TreeBuilder->new;

    if ( ref $code1 ) { $t1->implicit_tags(0); $code1 = $$code1 }
    if ( ref $code2 ) { $t2->implicit_tags(0); $code2 = $$code2 }

    $t1->parse($code1);
    $t1->eof;
    $t2->parse($code2);
    $t2->eof;

    my $out1 = $t1->as_XML;
    my $out2 = $t2->as_XML;

    my $rv = ( $out1 eq $out2 );

    #print $rv? "RV TRUE\n" : "RV FALSE\n";
    #print $flip? "FLIP TRUE\n" : "FLIP FALSE\n";

    if ( $flip ? ( !$rv ) : $rv ) {
        if ( $DEBUG > 2 ) {
            print
                "In1 $code1\n",
                "In2 $code2\n",
                "Out1 $out1\n",
                "Out2 $out2\n",
                "\n\n";
        }
    }
    else {
        local $_;
        foreach my $line (
            '',
            "The following failure is at " . join( ' : ', caller ),
            "Explanation of failure: "
            . ( $flip ? 'same' : 'different' )
            . " parse trees!",
            "Input code 1:",
            $code1,
            "Input code 2:",
            $code2,
            "Output tree (as XML) 1:",
            $out1,
            "Output tree (as XML) 2:",
            $out2,
            )
        {
            $_ = $line;
            s/\n/\n# /g;
            print "# ", $_, "\n";
        }
    }

    $t1->delete;
    $t2->delete;

    return $rv;
}

# By default HTML::Parser will convert the &amp; to &
my $tree = HTML::TreeBuilder->new_from_content('&amp;foo; &bar;');

# No escaping of XML since custom entities are fine.
like( $tree->as_XML(),
    qr{<html><head></head><body>&amp;foo; &amp;bar;</body></html>}, "" );

# HTML gets escaped on output
like( $tree->as_HTML(),
    qr{<html><head></head><body>&amp;foo; &amp;bar;</body></html>}, "" );

# ignoring entities when parsing source makes it work like you expect XML to
my $tree3 = HTML::TreeBuilder->new( no_expand_entities => 1 );
$tree3->parse("<p>&amp;foo; &bar; &#39; &l</p>");
like( $tree3->as_HTML(),
    qr{<html><head></head><body><p>&amp;foo; &bar; &#39; &l</body></html>},
    "" );
like(
    $tree3->as_XML(),
    qr{<html><head></head><body><p>&amp;foo; &bar; &#39; &amp;l</p></body></html>},
    ""
);

