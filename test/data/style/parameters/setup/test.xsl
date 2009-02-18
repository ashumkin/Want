<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!-- Whenever you match any node or any attribute -->
  <xsl:output method="xml" encoding="iso-8859-2" indent="yes"/>
  <xsl:param name="test" select="''"/>
  <xsl:template match="node()|@*">
     <xsl:attribute name="test" >
     <xsl:value-of select="$test" />
    </xsl:attribute>
    <!-- Copy the current node -->   
    <xsl:copy>
      <!-- Including any attributes it has and any child nodes -->
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
