<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html"/>

<xsl:template match="/">
  <xsl:for-each select="catalog/item">
    <xsl:text>{</xsl:text><xsl:apply-templates select="child::*|child::text()"/><xsl:text>}</xsl:text>
    <xsl:if test="position() != last()">
      <xsl:text>, </xsl:text>
    </xsl:if>
  </xsl:for-each>
</xsl:template>

<xsl:template match="rule | file">
  <xsl:text>"</xsl:text><xsl:value-of select="name()"/><xsl:text>": "</xsl:text><xsl:value-of select="."/><xsl:text>"</xsl:text>
  <xsl:if test="position() != last()">
    <xsl:text>, </xsl:text>
  </xsl:if>
</xsl:template>

<xsl:template match="context | tip">
<xsl:text>"</xsl:text><xsl:value-of select="name()"/><xsl:text>": "</xsl:text><xsl:apply-templates select="." mode="escape"/><xsl:text>"</xsl:text>
  <xsl:if test="position() != last()">
    <xsl:text>, </xsl:text>
  </xsl:if>
</xsl:template>

<xsl:template match="text()|@*" mode="escape">
  <xsl:variable name="newtext">
    <!-- Escape the double quotes -->
    <xsl:call-template name="string-replace-all">
      <xsl:with-param name="text">
        <!-- Escape the backslashes first -->
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="."/>
          <xsl:with-param name="replace" select="'\'"/>
          <xsl:with-param name="by" select="'\\'"/>
        </xsl:call-template>
      </xsl:with-param>
      <xsl:with-param name="replace" select="'&quot;'"/>
      <xsl:with-param name="by" select="'\&quot;'"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:value-of select="$newtext"/>
</xsl:template>

<xsl:template name="string-replace-all">
  <xsl:param name="text"/>
  <xsl:param name="replace"/>
  <xsl:param name="by"/>
  <xsl:choose>
    <xsl:when test="contains($text, $replace)">
      <xsl:value-of select="substring-before($text,$replace)"/>
        <xsl:value-of select="$by"/>
        <xsl:call-template name="string-replace-all">
          <xsl:with-param name="text" select="substring-after($text,$replace)"/>
          <xsl:with-param name="replace" select="$replace"/>
          <xsl:with-param name="by" select="$by"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$text"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>
</xsl:stylesheet>
