use Test;
BEGIN { plan tests => 2 }
END { ok(0) unless $loaded }

use XML::XSLT::Wrapper;
$loaded = 1;

my $missing=undef;
eval {require XML::LibXSLT;};
if ($@) {$missing=1};

my $xml_file = 'example.xml';
my $xsl_file = 'example.xsl';
my $out_file = 'out.xml';
unlink $out_file;

my $xslt;
my $result=undef;
unless (defined($missing)) {
    $xslt = XML::XSLT::Wrapper->new( 'ProcessorList' => ['libxslt'], );
    $result = $xslt->transform( 
		    xml => $xml_file,
		    xsl => $xsl_file,
		    XSLParams => { 'COMEIN' => 'knock knock', },
		);
}

skip($missing, defined(1), defined($result));

$result=undef;
unless (defined($missing)) {
    $result = $xslt->transform( 
		    xml => $xml_file,
		    xsl => $xsl_file,
		    XSLParams => { 'COMEIN' => 'knock knock', },
		    OutFile => $out_file,
		);
}

skip($missing, '', $result);

