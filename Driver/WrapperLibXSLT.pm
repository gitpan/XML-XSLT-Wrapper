# base class.
package Driver::WrapperLibXSLT;

use lib '.';
use Driver::BaseClass;
@ISA = qw(Driver::BaseClass);

use XML::XSLT::Wrapper;

use vars qw(
        $xslt
        $stylesheet
        $input
        );

sub init {
    $xslt = XML::XSLT::Wrapper->new( 'ProcessorList' => ['libxslt'], 
    );
}

sub load_stylesheet {
    my ($filename) = @_;
#    $stylesheet = $filename;
    my %pre_parsed = $xslt->pre_parse( XSLFile => $filename );
    $stylesheet = $pre_parsed{'libxslt'}->{'xsl'};
}

sub load_input {
    my ($filename) = @_;
#    $input = $filename;
    my %pre_parsed = $xslt->pre_parse( XMLFile => $filename );
    $input = $pre_parsed{'libxslt'}->{'xml'};
}

sub run_transform {
    my ($output) = @_;
    $results = $xslt->transform(  'XMLParsed' => $input,
				'XSLParsed' => $stylesheet,
				'OutFile' => $output,
				);
}

1;
