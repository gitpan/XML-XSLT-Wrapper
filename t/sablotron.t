use Test;
BEGIN { plan tests => 1 }
END { ok(0) unless $loaded }
$loaded=1;
use XML::XSLT::Wrapper;

my $missing = undef;
eval { require XML::Sablotron; };
if ($@) {$missing = 1};
eval "use XML::Sablotron;";
if ($@) {$missing = 1};

my $xml_file = 'example.xml';
my $xsl_file = 'example.xsl';

my $result = undef;
unless (defined($missing)) {
    my $xslt = XML::XSLT::Wrapper->new( ProcessorList => ['sablotron']);
    $result = $xslt->transform(
		    xml => $xml_file,
		    xsl => $xsl_file,
		    XSLParams => { 'COMEIN' => 'knock knock'  },
		);
}

skip($missing, defined(1), defined($result));

