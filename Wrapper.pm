package XML::XSLT::Wrapper;
# Copyright (C) 2001, Colin Muller: colin@durbanet.co.za
# This module may be used, distributed and modified
# under the same terms as Perl itself
# $Id: Wrapper.pm,v 1.16 2001/06/02 12:49:21 colin Exp $

use strict;
use vars qw($VERSION $AUTOLOAD);

$VERSION = '0.32';
$XML::XSLT::Wrapper::debug = undef;

sub new {
    my ($proto, %args) = @_;
    my $class = ref($proto) || $proto;
    my $self = {};
    foreach my $key (keys %args) {
	$self->{$key} = $args{$key};
    }
    if (defined($args{Debug})) {
	$XML::XSLT::Wrapper::debug = 1;
    }
    unless (defined $self->{ProcessorList}) {
	my @processors = qw(libxslt sablotron xalan xslt xt saxon);
	$self->{ProcessorList} = \@processors;
    }
    bless ($self, $class);
    my $processor_array_ref = $self->{ProcessorList};
    for my $i (0 .. $#$processor_array_ref) {
	my $processor_init = lc($processor_array_ref->[$i]) . '_init';
	unless ($self->$processor_init()) {
debug("Could not init $processor_init");
	    $processor_array_ref->[$i] = undef;
	}
    }
    return $self;
}

sub transform {
    my ($self, %params) = @_;
#debug("In sub transform");
    my $processor_array_ref = $self->{ProcessorList};
PROC:
    for my $i (0 .. $#$processor_array_ref) {
	if (defined($processor_array_ref->[$i])) {
debug("Trying processor: $processor_array_ref->[$i]");
	    my $result;
	    my $processor = lc($processor_array_ref->[$i]);
	    eval { $result = $self->$processor(%params) };
	    unless ( ($@) || ( !defined($result) ) ) {
		return $result;
		last PROC;
	    }
	}
    } # for
    return undef;
}

sub parse_params {
#    $parsed_params = parse_params($params->{'XSLParams'});
#    $params->{'XSLParamString'} = $parsed_params->[0];
#    $params->{'XSLParamHash'} = $parsed_params->[1];
#    $params->{'XSLParamArray'} = $parsed_params->[2];
    my $params_ref = shift;
    my ($par_str, %par_hash, @par_array) = ('', {}, []);
    if (ref($params_ref) eq 'HASH') {
	foreach my $key (keys %$params_ref) {
	    my $q = '';
	    if ($params_ref->{$key} !~ /'/) {
		$q = "'";
	    } elsif ($params_ref->{$key} !~ /"/) {
		$q = '"';
	    }
	    $par_str .= $key . '='
		. $q . $params_ref->{$key} . $q 
		. ' '
		;
	}
	@par_array = %$params_ref;
	%par_hash = %$params_ref;
    } elsif (ref($params_ref) eq 'ARRAY') {
	my $i;
	for ($i=0; $i < $#$params_ref; $i = $i+2) {
	    my $q = '';
	    if ($params_ref->[$i+1] !~ /'/) {
		$q = "'";
	    } elsif ($params_ref->[$i+1] !~ /"/) {
		$q = '"';
	    }
	    $par_str .= $params_ref->[$i] . '=' . 
		$q . $params_ref->[$i+1] . $q 
		. ' '
		;
	    $par_hash{$params_ref->[$i]} = $params_ref->[$i+1];
	}
	@par_array = @$params_ref;
    }
    return [$par_str, \%par_hash, \@par_array];
} 

sub debug {
    if (defined($XML::XSLT::Wrapper::debug)) {
	my ($message) = @_;
	if (defined($message)) {
	    warn "DEBUG: ", $message, "\n";
	}
    }
    return;
}

my $_SUBS = {};

sub AUTOLOAD {
    no strict "refs";
    my ($self, %params) = @_;
#debug("starting autoload: $AUTOLOAD");
    unless (defined($_SUBS->{$AUTOLOAD})) { return undef; }
debug("evaling autoload: $AUTOLOAD");
    eval "$_SUBS->{$AUTOLOAD}";
#debug("done autoload: $AUTOLOAD");
    return $self->$AUTOLOAD(%params);
}

sub DESTROY {
}

# Everything below here is AUTOLOADed if required
$_SUBS->{'XML::XSLT::Wrapper::libxslt_init'} = 
<<'END_OF_SUB';
sub libxslt_init {
    my ($self, %params) = @_;
    eval { require XML::LibXSLT; };
    if ($@) {
	return undef;
    }
    use XML::LibXSLT;
    eval { require XML::LibXML; };
    if ($@) {
	return undef;
    }
    use XML::LibXML;
    $XML::XSLT::Wrapper::libxmlparser = XML::LibXML->new();
    $XML::XSLT::Wrapper::libxsltprocessor = XML::LibXSLT->new();
    return 1;
}
END_OF_SUB

$_SUBS->{'XML::XSLT::Wrapper::pre_parse'} = 
<<'END_OF_SUB';
sub pre_parse {
    my ($self, %params) = @_;
    my $processor_array_ref = $self->{ProcessorList};
    my %pre_parsed;
PROC:
    for my $i (0 .. $#$processor_array_ref) {
	if (defined($processor_array_ref->[$i])) {
debug("Preparsing with: $processor_array_ref->[$i]");
	    my ($parsed_xml, $parsed_xsl);
	    my $processor = lc($processor_array_ref->[$i]);
	    $pre_parsed{$processor} = {};
	    my $preparser = $processor . '_pre_parse';
	    eval
	    {
	    ($parsed_xml, $parsed_xsl) = $self->$preparser(%params);
	    };
	    unless ($@) {
		$pre_parsed{$processor}{'xml'} = $parsed_xml;
		$pre_parsed{$processor}{'xsl'} = $parsed_xsl;
	    }
	}
    }
    return %pre_parsed;
}
END_OF_SUB

$_SUBS->{'XML::XSLT::Wrapper::libxslt_pre_parse'} = 
<<'END_OF_SUB';
sub libxslt_pre_parse {
#debug("in libxslt_pre_parse");
    my ($self, %params) = @_;
    my ($xml_parsed, $xsl_parsed);
    if (defined $params{XMLFile})
    {
debug($params{XMLFile});
	$xml_parsed = $XML::XSLT::Wrapper::libxmlparser->parse_file($params{XMLFile});
    }
    if (defined $params{XSLFile})
    {
debug($params{XSLFile});
	my $parsed_stylesheet = $XML::XSLT::Wrapper::libxmlparser->parse_file($params{XSLFile});
	$xsl_parsed = $XML::XSLT::Wrapper::libxsltprocessor->parse_stylesheet($parsed_stylesheet)   
    }
    return ($xml_parsed, $xsl_parsed);
}
END_OF_SUB
    
$_SUBS->{'XML::XSLT::Wrapper::libxslt'} = 
<<'END_OF_SUB';
sub libxslt {
    my ($self, %params) = @_;
#debug("In sub libxslt");

    my $parsed_params;
    if (
	(!defined($params{XSLParamHash}))
	&& (defined($params{XSLParams}))
	)
    {
	$parsed_params = parse_params($params{XSLParams});
	$params{XSLParamHash} = $parsed_params->[1];
    }

    my $parser = $XML::XSLT::Wrapper::libxmlparser;
    my $xslt = $XML::XSLT::Wrapper::libxsltprocessor;
    my ($stylesheet, $source, $style_doc);
    if (defined $params{XMLParsed}) {
	$source = $params{XMLParsed};
    } else {
	if (defined($params{XMLFile})) {
	    $source = $parser->parse_file($params{XMLFile});
	} elsif (defined($params{XMLString})) {
	    $source = $parser->parse_string($params{XMLString});
	} elsif (defined $params{xml}) {
	    if ($params{xml} =~ /^\s*</) {
		$source = $parser->parse_string($params{xml});
	    } elsif (-f $params{xml}) {
		$source = $parser->parse_file($params{xml});
	    }
	} else {
	    return undef;
	}
    }

    if (defined $params{XSLParsed}) {
	$stylesheet = $params{XSLParsed};
    } else {
	if (defined($params{XSLFile})) {
	    $style_doc = $parser->parse_file($params{XSLFile});
	} elsif (defined($params{XSLString})) {
	    $style_doc = $parser->parse_string($params{XSLString});
	} elsif (defined $params{xsl}) {
	    if ($params{xsl} =~ /^\s*</) {
		$style_doc = $parser->parse_string($params{xsl});
	    } elsif (-f $params{xsl}) {
		$style_doc = $parser->parse_file($params{xsl});
	    }
	} else {
	    return undef;
	}
	$stylesheet = $xslt->parse_stylesheet($style_doc);
    }

    my $results = undef;
    if (defined($params{XSLParamHash})) {
	$results
	= $stylesheet->transform($source, %{$params{XSLParamHash}});
    } else {
	$results = $stylesheet->transform($source);
    }

    if (defined $params{out}) {
	warn "DEPRECATED: The parameter 'out' has been renamed 'OutFile'; future
	versions of the Wrapper will not work with 'out'\n";
	$params{OutFile} = $params{out};
    }
    if ( defined($params{OutFile}) ) {
	unlink $params{OutFile};
	$stylesheet->output_file($results, $params{OutFile});
	if (-f $params{OutFile}) {
	    return "";
	} else {
	    return undef
	}
    } else {
	my $ret_str = $stylesheet->output_string($results);
	return $ret_str;
    }
}
END_OF_SUB

$_SUBS->{'XML::XSLT::Wrapper::xalan_init'} = 
<<'END_OF_SUB';
sub xalan_init {
    my ($self, %params) = @_;
#debug("In sub xalan_init");
    eval { require XML::Xalan::Transformer; };
    if ($@) { return undef; }
    use XML::Xalan::Transformer;
    my $xalan;
    eval { $xalan = XML::Xalan::Transformer->new(); };
    if ($@) { return undef };
    $XML::XSLT::Wrapper::xalanprocessor = $xalan;
    return 1;
}
END_OF_SUB

$_SUBS->{'XML::XSLT::Wrapper::xalan'} = 
<<'END_OF_SUB';
sub xalan {
    my ($self, %params) = @_;
#debug("In sub xalan");
    
    my $xml = '';
    my $xml_temp_file;
    if (defined($params{XMLFile})) {
	$xml = $params{XMLFile};
    } elsif (defined($params{XMLString})) {
	$xml = $self->file_from_string($params{XMLString});
	$xml_temp_file = 1;
    } elsif (defined $params{xml}) {
	if ($params{xml} =~ /^\s*</) {
	    $xml = $self->file_from_string($params{xml});
	    $xml_temp_file = 1;
	} elsif (-f $params{xml}) {
	    $xml = $params{xml};
	} else {
	    return undef;
	}
    } else {
	return undef;
    }
	
    my $xsl = '';
    my $xsl_temp_file;
    if (defined($params{XSLFile})) {
	$xsl = $params{XSLFile};
    } elsif (defined($params{XSLString})) {
	$xsl = $self->file_from_string($params{XSLString});
	$xsl_temp_file = 1;
    } elsif (defined $params{xsl}) {
	if ($params{xsl} =~ /^\s*</) {
	    $xsl = $self->file_from_string($params{xsl});
	    $xsl_temp_file = 1;
	} elsif (-f $params{xsl}) {
	    $xsl = $params{xsl};
	} else {
	    return undef;
	}
    } else {
	return undef;
    }

    my $xalan = $XML::XSLT::Wrapper::xalanprocessor;

    my $result_str;
    if (defined($params{OutFile})) {
	unlink $params{OutFile};
	eval $xalan->transform_to_file($xml, $xsl, $params{OutFile});
	if ($@) {  return undef };
	if (-f $params{OutFile}) { $result_str = ''; }
    } else {
	eval { $result_str = $xalan->transform_to_data($xml, $xsl); };
	if ($@) {  return undef };
    }
    if ($xml_temp_file) { unlink $xml; }
    if ($xsl_temp_file) { unlink $xsl }
    return $result_str;
}
END_OF_SUB

$_SUBS->{'XML::XSLT::Wrapper::sablotron_init'} =
<<'END_OF_SUB';
sub sablotron_init {
    my ($self, %params) = @_;
    eval { require XML::Sablotron; };
    if ($@) { return undef; }
    use XML::Sablotron;
    $XML::XSLT::Wrapper::sablotronprocessor = XML::Sablotron->new();
    $XML::XSLT::Wrapper::sablotronprocessor->RegHandler(
		    0,
		    { MHError => \&myMHError,
		    MHMakeCode => \&myMHMakeCode,
		    MHLog => \&myMHLog
		});

    sub myMHMakeCode {
	my ($s, $processor, $severity, $facility, $code);
#	return $code;
	return 1;
    }

    sub myMHLog {
    my ($s, $processor, $code, $level, @fields);
    #       print LOGHANDLE "[Sablot: $code]\n" .  (join "\n", @fields, "");
	return 1;
    }

    sub myMHError {
	my ($s, $processor, $code, $level, @fields) = @_;
#	my $mess = "[Sablot: $code]\n" .  (join "\n", @fields, "");
	return 1;
    }

    return 1;
}
END_OF_SUB

$_SUBS->{'XML::XSLT::Wrapper::sablotron'} =
<<'END_OF_SUB';
sub sablotron {
    my ($self, %params) = @_;
$|=1;
#debug("In sub sablotron");

    my $parsed_params;
    if (
	(!defined($params{XSLParamHash}))
	&& (defined($params{XSLParams}))
	)
    {
	$parsed_params = parse_params($params{XSLParams});
	$params{XSLParamArray} = $parsed_params->[2];
    }
    my $xsl_params_ref = $params{XSLParamArray};

    my ($xml_str, $xml_file);
    if (defined($params{XMLFile})) {
	$xml_file = $params{XMLFile};
    } elsif (defined($params{XMLString})) {
	$xml_str = $params{XMLString};
    } elsif (defined $params{xml}) {
	if ($params{xml} =~ /^\s*</) {
	    $xml_str = $params{xml};
	} elsif (-f $params{xml}) {
	    $xml_file = $params{xml};
	}
    } else {
	return undef;
    }

    my ($xsl_str, $xsl_file);
    if (defined($params{XSLFile})) {
	$xsl_file = $params{XSLFile};
    } elsif (defined($params{XSLString})) {
	$xsl_str = $params{XSLString};
    } elsif (defined $params{xsl}) {
	if ($params{xsl} =~ /^\s*</) {
	    $xsl_str = $params{xsl};
	} elsif (-f $params{xsl}) {
	    $xsl_file = $params{xsl};
	}
    } else {
	return undef;
    }

    my $sab = $XML::XSLT::Wrapper::sablotronprocessor;

    my $out_arg = "arg:/res";
    if (defined $params{out}) {
	warn "DEPRECATED: The parameter 'out' has been renamed 'OutFile'; future
	versions of the Wrapper will not work with 'out'\n";
	$params{OutFile} = $params{out};
    }
    if (defined $params{OutFile}) {
	$out_arg = $params{OutFile};
	unlink $params{OutFile};
    }

    my $xsl_arg = "arg:/xsl_str";
    my $xsl_arg_name = "xsl_str";
    my $xsl_arg_val = $xsl_str;
    if (defined $xsl_file) {
	$xsl_arg = $xsl_file;
	$xsl_arg_name = "xsl_file";
	$xsl_arg_val = $xsl_file;
    }
    my $xml_arg = "arg:/xml_str";
    my $xml_arg_name = "xml_str";
    my $xml_arg_val = $xml_str;
    if (defined $xml_file) {
	$xml_arg = $xml_file;
	$xml_arg_name = "xml_file";
	$xml_arg_val = $xml_file;
    }

    my $result_code;

eval {
    $result_code = 
	$sab->RunProcessor(
	    $xsl_arg, 
	    $xml_arg, 
	    $out_arg, 
	    $xsl_params_ref,
	    [$xsl_arg_name, $xsl_arg_val, 
	    $xml_arg_name, $xml_arg_val]
	    ); 
    };
    if ( ($@) || ($?) ){
	return undef;
    }

    $sab->ClearError();
    my $result_str;
    if (defined $params{OutFile}) {
	$sab->FreeResultArgs();
	if (-f $params{OutFile}) {
	    return '';
	} else {
	    return undef;
	}
    } else {
	eval { $result_str = $sab->GetResultArg("res"); };
	if ($@) {
	    return undef;
	}
	$sab->FreeResultArgs();
    }
    return $result_str;
}
END_OF_SUB

$_SUBS->{'XML::XSLT::Wrapper::xslt_init'} =
<<'END_OF_SUB';
sub xslt_init {
    eval { require XML::XSLT; };
    if ($@) {
	return undef;
    }
    return 1;
}
END_OF_SUB

$_SUBS->{'XML::XSLT::Wrapper::xslt'} =
<<'END_OF_SUB';
sub xslt {
    my ($self, %params) = @_;
#debug("In sub xslt");
    my $xml = "";
    my $xml_temp_file;
    if (defined($params{XMLFile})) {
	$xml = $params{XMLFile};
    } elsif (defined($params{XMLString})) {
	$xml = $self->file_from_string($params{XMLString});
	$xml_temp_file = 1;
    } elsif (defined $params{xml}) {
	if ($params{xml} =~ /^\s*</) {
	    $xml = $self->file_from_string($params{xml});
	    $xml_temp_file = 1;
	} elsif (-f $params{xml}) {
	    $xml = $params{xml};
	}
    } else {
	return undef;
    }

    my $xsl = "";
    my $xsl_temp_file;
    if (defined($params{XSLFile})) {
	$xsl = $params{XSLFile};
    } elsif (defined($params{XSLString})) {
	$xsl = $self->file_from_string($params{XSLString});
	$xsl_temp_file = 1;
    } elsif (defined $params{xsl}) {
	if ($params{xsl} =~ /^\s*</) {
	    $xsl = $self->file_from_string($params{xsl});
	    $xsl_temp_file = 1;
	} elsif (-f $params{xsl}) {
	    $xsl = $params{xsl};
	}
    } else {
	return undef;
    }

    if (defined $params{out}) {
	warn "DEPRECATED: The parameter 'out' has been renamed 'OutFile'; future
	versions of the Wrapper will not work with 'out'\n";
	$params{OutFile} = $params{out};
    }
    if (defined $params{OutFile}) { unlink $params{OutFile}; }

    my $xslt = XML::XSLT->new($xsl);
    my $result_str;
    eval { $result_str = $xslt->serve($xml); };
    if ($@) {
	return undef;
    }
    if ($xml_temp_file) { unlink $xml; }
    if ($xsl_temp_file) { unlink $xsl }
    if (defined $params{OutFile}) {
	open F, ">$params{OutFile}";
	print F $result_str;
	close F;
	if (-f $params{OutFile}) {
	    return '';
	} else {
	    return undef;
	}
    }
    return $result_str;
}
END_OF_SUB

$_SUBS->{'XML::XSLT::Wrapper::xt_init'} =
<<'END_OF_SUB';
sub xt_init {
    my ($self, %params) = @_;
    my $classpath = $self->{'JavaClassPath'} || $ENV{'CLASSPATH'} || '';
    if (
	($classpath =~ /xt\.jar/)
	&& ($classpath =~ /xp\.jar/)
	&& ($classpath =~ /sax\.jar/)
	)
    { return 1 }
    return undef;
}
END_OF_SUB

$_SUBS->{'XML::XSLT::Wrapper::xt'} =
<<'END_OF_SUB';
sub xt {
    my ($self, %params) = @_;
#debug("In sub xt");
    my $parsed_params;
    if (
	(!defined($params{XSLParamString}))
	&& (defined($params{XSLParams}))
	)
    {
	$parsed_params = parse_params($params{XSLParams});
	$params{XSLParamString} = $parsed_params->[0];
    }

    my ($xml_str, $xml_file);
    my $xml_temp_file;
    if (defined($params{XMLFile})) {
	$xml_file = $params{XMLFile};
    } elsif (defined($params{XMLString})) {
	$xml_file = $self->file_from_string($params{XMLString});
	$xml_temp_file = 1;
    } elsif (defined $params{xml}) {
	if ($params{xml} =~ /^\s*</) {
	    $xml_file = $self->file_from_string($params{xml});
	    $xml_temp_file = 1;
	} elsif (-f $params{xml}) {
	    $xml_file = $params{xml};
	}
    } else {
	return undef;
    }

    my ($xsl_str, $xsl_file);
    my $xsl_temp_file;
    if (defined($params{XSLFile})) {
	$xsl_file = $params{XSLFile};
    } elsif (defined($params{XSLString})) {
	$xsl_file = $self->file_from_string($params{XSLString});
	$xsl_temp_file = 1;
    } elsif (defined $params{xsl}) {
	if ($params{xsl} =~ /^\s*</) {
	    $xsl_file = $self->file_from_string($params{xsl});
	    $xsl_temp_file = 1;
	} elsif (-f $params{xsl}) {
	    $xsl_file = $params{xsl};
	}
    } else {
	return undef;
    }

    my $out_file;
    if (defined $params{out}) {
	warn "DEPRECATED: The parameter 'out' has been renamed 'OutFile'; future
	versions of the Wrapper will not work with 'out'\n";
	$params{OutFile} = $params{out};
    }
    if (defined $params{OutFile})
	{
	    unlink $out_file;
	    $out_file = $params{OutFile};
	} else {
	    $out_file = '';
	}

    my $xsl_params = $params{XSLParamString} || "";
    my $java_bin = $self->{JavaBin} || "java";
    my $classpath = $ENV{CLASSPATH} || "";
    $classpath = $self->{JavaClassPath} || $classpath;
    $classpath = " -classpath " . $classpath;
    my $java_command = "-Dcom.jclark.xsl.sax.parser=com.jclark.xml.sax.CommentDriver com.jclark.xsl.sax.Driver";
    $java_command = $self->{'JavaCommand'} || $java_command;

    my $call = "$java_bin $classpath $java_command $xml_file $xsl_file $out_file $xsl_params";
#debug($call);
    my $result_str = undef;
    $result_str = qx($call);
    if ($?) { return undef; }
    if (defined $params{OutFile}) {
	if (-f $params{OutFile}) {
	    return '';
	} else {
	    return undef;
	}
    }
    if ($xml_temp_file) { unlink $xml_file; }
    if ($xsl_temp_file) { unlink $xsl_file }
    if ($result_str eq '') { return undef; }
    return $result_str;
} # sub xt
END_OF_SUB

$_SUBS->{'XML::XSLT::Wrapper::saxon_init'} =
<<'END_OF_SUB';
sub saxon_init {
    my ($self, %params) = @_;
    my $classpath = $self->{'JavaClassPath'} || $ENV{'CLASSPATH'} || '';
    if ($classpath =~ /saxon\.jar/) { return 1 }
    return undef;
}
END_OF_SUB

$_SUBS->{'XML::XSLT::Wrapper::saxon'} =
<<'END_OF_SUB';
sub saxon {
#debug("In sub saxon");
    my ($self, %params) = @_;
    my $parsed_params;
    if (
	(!defined($params{XSLParamString}))
	&& (defined($params{XSLParams}))
	)
    {
	$parsed_params = parse_params($params{XSLParams});
	$params{XSLParamString} = $parsed_params->[0];
    }

    my ($xml_str, $xml_file);
    my $xml_temp_file;
    if (defined($params{XMLFile})) {
	$xml_file = $params{XMLFile};
    } elsif (defined($params{XMLString})) {
	$xml_file = $self->file_from_string($params{XMLString});
	$xml_temp_file = 1;
    } elsif (defined $params{xml}) {
	if ($params{xml} =~ /^\s*</) {
	    $xml_file = $self->file_from_string($params{xml});
	    $xml_temp_file = 1;
	} elsif (-f $params{xml}) {
	    $xml_file = $params{xml};
	}
    } else {
	return undef;
    }

    my ($xsl_str, $xsl_file);
    my $xsl_temp_file;
    if (defined($params{XSLFile})) {
	$xsl_file = $params{XSLFile};
    } elsif (defined($params{XSLString})) {
	$xsl_file = $self->file_from_string($params{XSLString});
	$xsl_temp_file = 1;
    } elsif (defined $params{xsl}) {
	if ($params{xsl} =~ /^\s*</) {
	    $xsl_file = $self->file_from_string($params{xsl});
	    $xsl_temp_file = 1;
	} elsif (-f $params{xsl}) {
	    $xsl_file = $params{xsl};
	}
    } else {
	return undef;
    }

    my $xsl_params = $params{XSLParamString} || '';
    my $java_bin = $self->{JavaBin} || "java";
    my $out_file;
    if (defined $params{out}) {
	warn "DEPRECATED: The parameter 'out' has been renamed 'OutFile'; future
	versions of the Wrapper will not work with 'out'\n";
	$params{OutFile} = $params{out};
    }
    if (defined $params{OutFile}) { $out_file = $params{OutFile}; }
    if (defined $out_file)
	{
	    unlink $out_file;
	    $out_file = ' -o ' . $out_file;
	} else {
	    $out_file = '';
	}

    my $classpath = $ENV{CLASSPATH} || '';
    $classpath = $self->{JavaClassPath} || $classpath;
    $classpath = " -classpath " . $classpath;
$xsl_params =~ s/\n/ /g;
#debug($xsl_params);
    my $java_args = $self->{JavaArgs} || "";
    my $java_command = $self->{JavaCommand} || "com.icl.saxon.StyleSheet";
    my $call = "$java_bin $java_args $classpath $java_command $out_file $xml_file $xsl_file $xsl_params";
#debug($call);
    my $result_str = undef;
    eval { $result_str = qx($call); };
    if ($?) { return undef; }
    if (defined $params{OutFile}) {
	if (-f $params{OutFile}) {
	    return '';
	} else {
	    return undef;
	}
    }
    if ($xml_temp_file) { unlink $xml_file; }
    if ($xsl_temp_file) { unlink $xsl_file; }
    if ($result_str eq '') { return undef; }
    return $result_str;
}
END_OF_SUB

$_SUBS->{'XML::XSLT::Wrapper::file_from_string'} =
<<'END_OF_SUB';
sub file_from_string {
    my ($self, $xml_string) = @_;
#debug($xml_string);
    use POSIX;
    my $fn;
    do {
	$fn = tmpnam();
    } until sysopen(TMP,$fn,O_WRONLY|O_CREAT|O_EXCL,0600);
    print TMP $xml_string;
    close TMP;
    return $fn;
}
END_OF_SUB

1;
__END__

=head1 NAME

XML::XSLT::Wrapper - Consistent interface to XSLT processors

=head1 SYNOPSIS

    use XML::XSLT::Wrapper;
    my $xslt = XML::XSLT::Wrapper->new(
	    ProcessorList => ['libxslt', 'sablotron'],
	    )

    $result = $xslt->transform(
		XMLFile => $xml_filename
		XSLFile => $xsl_filename
#OR:		XMLString => $xml_string
#OR:		XSLString => $xsl_string
#OR:		xml => $xml_filename_or_string,
#OR:		xsl => $xsl_filename_or_string,
		XSLParams => { 'COMEIN' => 'knock knock',
				'GOAWAY' => 'conk conk' },
	    );
	    
    $result = $xslt->transform(
		OutFile => $output_filename,
		XMLFile => $xml_filename
		XSLFile => $xsl_filename
		XSLParams => [ 'COMEIN', 'knock knock',
				'GOAWAY', 'conk conk' ],
	    );
    
    
    # NB: The pre_parsing interface is likely to change:
    %pre_parsed = $xslt->pre_parse(
		XSLFile => $xsl_filename
	    );
    $pre_parsed{$processor}{'xsl'} = $parsed_xsl;
    
    foreach (@xml_files) {
	$result = $xslt->transform(
		    XSLParsed = $parsed_xsl;
		    OutFile => $output_filename,
		    XMLFile => $_,
		    XSLParams => [ 'COMEIN', 'knock knock',
				    'GOAWAY', 'conk conk' ],
		);
    }

See also examples/*.pl, t/*.t and Driver/*.pm in the distribution directory.

=head1 DESCRIPTION

Provides a consistent interface to various XSLT processors.  Tries each
of a supplied list of processors in turn until one performs a successful
transform. If no list is given, tries all the processors it knows until
one works. Does its best to fail gracefully whenever a processor does
not work for some reason.

Can return the result of the transform as a string, or write it to a
specified file.

For those processors which can accept parameters to an XSLT stylesheet,
XML::XSLT::Wrapper can accept these as hash of name-value pairs, or as
an array of [name, value, name, value, ...]

On completion, returns:
    - '' if it has written an output file
    - the result string if it has succeeded but not written an output file
    - undef if it has failed

Currently knows how to use XML::LibXSLT, XML::Xalan, XML::Sablotron,
XML::XSLT as well as the Java processors XT and Saxon. You need to set
your CLASSPATH environment variable first for the Java processors, or
pass it to the transform in a JavaClassPath hash element.  In a future
version, there will be a parameter to turn off support for the Java
processors. The XML::Sablotron I've tested with is 0.52.

=head1 METHODS

new - The constructor for XML::XSLT::Wrapper. Options are passed as
keyword value pairs. Recognized options are:

	- ProcessorList - A list of Processor names, any of:

	libxslt sablotron xalan xslt xt saxon

	The Wrapper will try each processor in turn, in the order given
	in the list. The names are matched case-insensitively, so
	LibXSLT will achieve the same as libxslt, etc.

	If this option is not supplied, the Wrapper will attempt each of
	these processors in turn.
	
	- Debug - if defined, turns on some debugging output.

transform - Processes the specified XML using the specified XSL stylesheet. Either or both of the XML and XSL can be given as filenames or strings. Options are passed as keyword value pairs. Recognized options are:

	- XMLFile - The name of the XML file to process

	- XSLFile - The name of the XSL file to use in processing the
	  XML

	- XMLString - A string containing the XML to process

	- XSLString - A string containing the XSLT Stylesheet to use in
	  processing the XML

	- XMLParsed - A reference to a pre-parsed version of the XSL
	  stylesheet to be used in processing the XML. Use of this is
	  not sensible unless you specified just a single processor.
	  
	- XSLParsed - A reference to a pre-parsed version of the XML to
	  process. Use of this is not sensible unless you specified just
	  a single processor.  

	- OutFile - the name of a file to which the result of the
	  transformation should be written. The file will be created if
	  it does not exist, and will be replaced if it does.

	- xml - Either the name of the XML file to process or a string
	  containing the XML to process. The Wrapper will detect which
	  it is.

	- xsl - Either the name of the XSL file to use in processing the
	  XML or a string containing the XSLT Stylesheet to use in
	  processing the XML. The Wrapper will detect which it is.

	- out - DEPRECATED: replaced by OutFile, and will disappear in
	  time. Has exactly the same meaning and usage as OutFile.

	- XSLParams - Either a hash of name-value pairs or an array of
	  [name, value, name, value, ...]. These will be passed as
	  parameters to the XSL Stylesheet.

pre_parse - WARNING: While any part of the Wrapper may change, this
method is particularly likely to. Takes XMLFile and/or XSLFile
parameters, and returns a hash with two key-value pairs:
    $pre_parsed{$processor}{'xml'} = $parsed_xml;
    $pre_parsed{$processor}{'xsl'} = $parsed_xsl;
    where $processor is the
lower-cased name of a processor know to XML::XSLT::Wrapper

=head1 BUGS

This is still an early version, and subject to change.

Does not recover gracefully when XML::Sablotron dumps core on 
XSLTMark tests.

(?) The check on whether the classpath contains the necessary Java
programs may be a bit iffy. Suggestions on how to improve it welcome.

The tests ("make test") are not at all comprehensive

=head1 AUTHOR

Colin Muller, colin@durbanet.co.za

Copyright (C) 2001, Colin Muller, colin@durbanet.co.za
This module may be used, distributed and modified
under the same terms as Perl itself

=head1 CONTRIBUTORS

Saxon support and various ideas contributed by Steve Tinney,
stinney@sas.upenn.edu.

=head1 SEE ALSO

XML::LibXSLT, XML::Xalan, XML::Sablotron, XML::XSLT.

=cut
