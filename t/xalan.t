use Test;
BEGIN { plan tests => 1 }
END { ok(0) unless $loaded }

use XML::XSLT::Wrapper;
$loaded = 1;

my $missing = undef;
eval {require XML::Xalan::Transformer;};
if ($@) {
    $missing=1;
} else {
    eval "use XML::Xalan::Transformer";
}

my $xml_file = 'example.xml';
my $xsl_file = 'example.xsl';

my $result=undef;
unless (defined($missing)) {
    my $xslt = XML::XSLT::Wrapper->new( ProcessorList => ['xalan'],);
    $result = $xslt->transform(
		    XMLFile => $xml_file,
		    XSLFile => $xsl_file,
		);
}

skip($missing, defined(1), defined($result));

