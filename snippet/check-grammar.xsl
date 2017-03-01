<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html"/>
<xsl:template match="/">
    <xsl:for-each select="catalog/item">
      <xsl:text>{"file":"</xsl:text><xsl:value-of select="file"/>"<xsl:text>,"context":"</xsl:text><xsl:value-of select="context"/><xsl:text>","tip":"</xsl:text><xsl:apply-templates select="tip"/><xsl:text>","rule":"</xsl:text><xsl:value-of select="rule"/><xsl:text>"}</xsl:text>
      <xsl:if test="position() != last()">
        <xsl:text>, </xsl:text>
      </xsl:if>
    </xsl:for-each>
</xsl:template>
<xsl:template match="br">
  <br/>
</xsl:template>
</xsl:stylesheet>
