use strict;
use XML::XSLT::Wrapper;

my $xml_file = 'example.xml';
my $xsl_file = 'example.xsl';

my $result = undef;

my $xslt = XML::XSLT::Wrapper->new(  'ProcessorList' => ['libxslt'],
				    'Debug' => 1 
				    );
$result = $xslt->transform( 
		xml => $xml_file,
		xsl => $xsl_file,
		XSLParams => { 'COMEIN' => 'knock knock'  },
		
	    );

print "\n1: ";
if (!(defined($result))) {
    print "Transform failed: \$result undefined\n";
} elsif ($result eq '') {
    print "Wrote outfile\n";
} else {
    print "Result string received:\n", $result;
}

$result = $xslt->transform( 
		xml => $xml_file,
		xsl => $xsl_file,
		XSLParams => [ 'COMEIN', 'knock knock' ],
		'OutFile' => 'out.xml',
		
	    );

print "\n2: ";
if (!defined($result)) {
    print "Transform failed: \$result undefined\n";
} elsif ($result eq '') {
    print "Wrote outfile\n";
} else {
    print "Result string received:\n", $result;
}

my %preparsed;
%preparsed = $xslt->pre_parse( XMLFile => $xml_file, XSLFile => $xsl_file);
my $xml_parsed = $preparsed{'libxslt'}{'xml'};
my $xsl_parsed = $preparsed{'libxslt'}{'xsl'};
$result = $xslt->transform( 
		XMLParsed => $xml_parsed,
		XSLParsed => $xsl_parsed,
		XSLParams => [ 'COMEIN', 'knock knock' ],
		
	    );

print "\n3: ";
if (!defined($result)) {
    print "Transform failed: \$result undefined\n";
} elsif ($result eq '') {
    print "Wrote outfile\n";
} else {
    print "Result string received:\n", $result;
}

