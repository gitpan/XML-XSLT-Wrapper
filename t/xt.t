use Test;
BEGIN { plan tests => 1 }
END { ok(0) unless $loaded }
use XML::XSLT::Wrapper;
$loaded=1;

my $missing=undef;
my $result=undef;
eval {
    my $xml_file = 'example.xml';
    my $xsl_file = 'example.xsl';

    my $xslt = XML::XSLT::Wrapper->new(
	ProcessorList => ['xt'],
	JavaCommand => '-Dcom.jclark.xsl.sax.parser=com.jclark.xml.sax.CommentDriver com.jclark.xsl.sax.Driver',
    );
    $result = $xslt->transform(
			xml => $xml_file,
			xsl => $xsl_file,
			XSLParams => { 'COMEIN' => 'knock knock',
					'GOOUT' => 'bang bang',
				    },
			Debug => 1,
		    );
};

if (($?) || ($@) || (!defined $result)) { $missing=1; };

skip($missing, defined(1), defined($result));

