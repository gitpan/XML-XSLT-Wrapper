use strict;
use XML::XSLT::Wrapper;

use XML::Xalan::Transformer;

my $xml_file = 'example.xml';
my $xsl_file = 'example.xsl';
my $out_file = 'out.xml';
unlink $out_file;

my $result=undef;
my $xslt = XML::XSLT::Wrapper->new( ProcessorList => ['xalan'],
Debug => 1
);
$result = $xslt->transform(
		    XMLFile => $xml_file,
		    XSLFile => $xsl_file,
		);


print "\n1: ";
if (!(defined($result))) {
    print "Transform failed: \$result undefined\n";
} elsif ($result eq '') {
    print "Wrote outfile\n";
} else {
    print "Result string received:\n", $result;
}

$result=undef;
$result = $xslt->transform(
		    XMLFile => $xml_file,
		    XSLFile => $xsl_file,
		    OutFile => $out_file,
		);


print "\n2: ";
if (!(defined($result))) {
    print "Transform failed: \$result undefined\n";
} elsif ($result eq '') {
    print "Wrote outfile\n";
} else {
    print "Result string received:\n", $result;
}

