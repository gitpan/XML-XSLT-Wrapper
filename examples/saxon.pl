use XML::XSLT::Wrapper;

use strict;
$|=1;
my $xml_file = 'example.xml';
my $xsl_file = 'example.xsl';
my $out_file = 'out.xml';

my $xslt = XML::XSLT::Wrapper->new(
    ProcessorList => ['saxon'],
    Debug => 1,
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

$/=undef;
open F, "<$xml_file";
my $xml_str = <F>;
close F;

$xsl_file = 'example.noinc.xsl';
open F, "<$xsl_file";
my $xsl_str = <F>;
close F;

$result = $xslt->transform(
		    xml => $xml_str,
		    xsl => $xsl_str,
		    XSLParams => { 'COMEIN' => 'knock knock',
				    'GOOUT' => 'bang bang',
				},
		);


print "\\n2: ";
if (!(defined($result))) {
    print "Transform failed: \$result undefined\n";
} elsif ($result eq '') {
    print "RESULT:$result:\n\nWrote outfile\n";
} else {
    print "Result string received:\n", $result;
}

$result = $xslt->transform(
		    XMLFile => $xml_file,
		    XSLFile => $xsl_file,
		    XSLParams => { 'COMEIN' => 'knock knock',
				    'GOOUT' => 'bang bang',
				},
		    OutFile => $out_file,
		);


print "\\n3: ";
if (!(defined($result))) {
    print "Transform failed: \$result undefined\n";
} elsif ($result eq '') {
    print "RESULT:$result:\n\nWrote outfile\n";
} else {
    print "Result string received:\n", $result;
}


