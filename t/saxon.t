use Test;
BEGIN { plan tests => 1 }
END { ok(0) unless $loaded }
$loaded=1;
use XML::XSLT::Wrapper;

my $missing=undef;
my $result=undef;
eval {
    my $xml_file = 'example.xml';
    my $xsl_file = 'example.xsl';

    my $xslt = XML::XSLT::Wrapper->new(
	ProcessorList => ['saxon'],
    );
    $result = $xslt->transform(
			xml => $xml_file,
			xsl => $xsl_file,
			XSLParams => { 'COMEIN' => 'knock knock',
					'GOOUT' => 'bang bang',
				    },
		    );
};



if (($?) || ($@) || (!defined $result)) { $missing=1; }

skip($missing, defined(1), defined($result));

