use strict;
use XML::XSLT::Wrapper;

my $xml_file = 'example.xml';
my $xsl_file = 'example.xsl';

my $result = undef;

my $xslt = XML::XSLT::Wrapper->new( ProcessorList => ['sablotron'],
				    Debug => 1
				    );
$result = $xslt->transform(
		XMLFile => $xml_file,
		XSLFile => $xsl_file,
		XSLParams => { 'COMEIN' => 'knock knock'  },
	    );

print "\n1:\n";
if (!defined($result)) {
    print "Transform failed: \$result undefined\n";
} elsif ($result eq '') {
    print "Wrote outfile\n";
} else {
    print $result;
}

$result = $xslt->transform(
		xml => $xml_file,
		xsl => $xsl_file,
		XSLParams => [ 'COMEIN', 'knock knock' ],
		'OutFile' => 'out.xml',
	    );

print "\n2:\n";
if (!defined($result)) {
    print "Transform failed: \$result undefined\n";
} elsif ($result eq '') {
    print "Wrote outfile\n";
} else {
    print $result;
}

