use XML::XSLT::Wrapper;

my $xml_file = 'example.xml';
my $xsl_file = 'example.xsl';

my $xslt = XML::XSLT::Wrapper->new(
);

my $result = $xslt->transform(
		    xml => $xml_file,
		    xsl => $xsl_file,
		    XSLParams => { 'COMEIN' => 'knock knock',
				    'GOOUT' => 'bang bang',
				},
		);


print "\n1: ";
if (!(defined($result))) {
    print "Transform failed: \$result undefined\n";
} elsif ($result eq '') {
    print "Wrote outfile\n";
} else {
    print "Result string received:\n", $result;
}

