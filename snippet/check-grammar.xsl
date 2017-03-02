<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html"/>
<xsl:template match="/">
  <xsl:for-each select="catalog/item">
    <xsl:variable name="escaped-context">
      <xsl:call-template name="replace-string">
        <xsl:with-param name="text" select="context"/>
        <xsl:with-param name="replace" select="'&quot;'" />
        <xsl:with-param name="with" select="'\&quot;'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="escaped-tip">
      <xsl:call-template name="replace-string">
        <xsl:with-param name="text" select="tip"/>
        <xsl:with-param name="replace" select="'&quot;'" />
        <xsl:with-param name="with" select="'\&quot;'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:text>{"file":"</xsl:text><xsl:value-of select="file"/>"<xsl:text>,"context":"</xsl:text><xsl:value-of select="$escaped-context"/><xsl:text>","tip":"</xsl:text><xsl:value-of select="$escaped-tip"/><xsl:text>","rule":"</xsl:text><xsl:value-of select="rule"/><xsl:text>"}</xsl:text>
    <xsl:if test="position() != last()">
      <xsl:text>, </xsl:text>
    </xsl:if>
  </xsl:for-each>
</xsl:template>
<xsl:template name="replace-string">
  <xsl:param name="text"/>
  <xsl:param name="replace"/>
  <xsl:param name="with"/>
  <xsl:choose>
    <xsl:when test="contains($text,$replace)">
      <xsl:value-of select="substring-before($text,$replace)"/>
      <xsl:value-of select="$with"/>
      <xsl:call-template name="replace-string">
        <xsl:with-param name="text" select="substring-after($text,$replace)"/>
        <xsl:with-param name="replace" select="$replace"/>
        <xsl:with-param name="with" select="$with"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$text"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>
</xsl:stylesheet>
