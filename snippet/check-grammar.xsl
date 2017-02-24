<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html"/>
<xsl:template match="/">
  <table id="reportTable" class="tablesorter">
    <thead>
    <tr bgcolor="#9acd32">
      <th style="text-align:left">File</th>
      <th style="text-align:left">Context</th>
      <th style="text-align:left">Tip</th>
      <th style="text-align:left">Rule</th>
    </tr>
    </thead>
    <tbody>
    <xsl:for-each select="catalog/item">
    <tr>
      <td><xsl:value-of select="file"/></td>
      <td><xsl:value-of select="context"/></td>
      <td><xsl:value-of select="tip"/></td>
      <td><xsl:value-of select="rule"/></td>
    </tr>
    </xsl:for-each>
    </tbody>
  </table>
</xsl:template>
</xsl:stylesheet>
