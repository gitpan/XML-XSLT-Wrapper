use Test;
BEGIN { plan tests => 1 }
END { ok(0) unless $loaded }

use XML::XSLT::Wrapper;
$loaded = 1;

my $missing=undef;
eval {require XML::LibXSLT;};
if ($@) {$missing=1};



my $xml_file = 'example.xml';
my $xsl_file = 'example.xsl';

my $result=undef;
unless (defined($missing)) {
    my $xslt = XML::XSLT::Wrapper->new();
    $result = $xslt->transform( 
		    xml => $xml_file,
		    xsl => $xsl_file,
		    XSLParams => { 'COMEIN' => 'knock knock', },
		);
}

skip($missing, defined(1), defined($result));

