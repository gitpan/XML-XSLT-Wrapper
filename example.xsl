<?xml version="1.0"?>
<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="1.0"
>
<xsl:include href="example.inc.xsl"/>
<xsl:param name="COMEIN">tringtring</xsl:param>
<xsl:template match = '/'>
<xsl:call-template name="included"/>
<xsl:value-of select="/test/one/inone"/>
<xsl:text>&#x0a;</xsl:text>
<xsl:value-of select="/test/two"/>
<xsl:text>&#x0a;</xsl:text>
<xsl:value-of select="$COMEIN"/>
<br/>
<xsl:variable name="mydoc" select="document('example.inc.xml')/included/two"/>
<xsl:value-of select="$mydoc"/>
</xsl:template>

</xsl:stylesheet>
