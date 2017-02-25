<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html"/>
<xsl:template match="/">
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <title><xsl:value-of select="//project/name"/></title>
  <link rel="stylesheet" href="/css/project.css"/>
</head>
<body>
  <h1><xsl:value-of select="//project/name"/></h1>
  <h2>spelling and grammar report</h2>
  <table>
    <thead>
      <tr>
        <th>Language</th>
        <th>Date</th>
        <th>Size</th>
        <th>MD5SUM</th>
      </tr>
    </thead>
    <tbody>
    <xsl:for-each select="project/languages/language">
    <xsl:sort select="language"/>
    <tr>
      <td>
         <a>
           <xsl:attribute name="href">
             <xsl:value-of select="url"/>
           </xsl:attribute>
           <xsl:value-of select="language"/>
         </a>
      </td>
      <td><xsl:value-of select="date"/></td>
      <td><xsl:value-of select="size"/></td>
      <td><xsl:value-of select="md5sum"/></td>
    </tr>
    </xsl:for-each>
    </tbody>
  </table>
  <figure>
    <img alt="Global translation: message stats by language" src="{concat('data:image/svg+xml;base64,', //project/msg)}"/>
    <figcaption>Fig.1 - Global translation - message stats by language.</figcaption>
  </figure>
  <figure>
    <img alt="Global translation: word stats by language" src="{concat('data:image/svg+xml;base64,', //project/wrd)}"/>
    <figcaption>Fig.2 - Global translation - word stats by language.</figcaption>
  </figure>
  <h2>Package List</h2>
  <table>
    <tr>
      <th>Package Name</th>
      <th>Description</th>
    </tr>
    <xsl:for-each select="project/components/component">
    <tr>
      <td style="white-space:nowrap;"><xsl:value-of select="name"/></td>
      <td><xsl:value-of select="desc"/></td>
    </tr>
    </xsl:for-each>
  </table><br/>
  <xsl:for-each select="project/languages/language">
  <xsl:sort select="language"/>
    <figure>
      <img>
        <xsl:attribute name="alt">
          <xsl:value-of select="svg-alt"/>
        </xsl:attribute>
        <xsl:attribute name="src">
       	  data:image/svg+xml;base64,<xsl:value-of select="svg"/>
       	</xsl:attribute>
      </img>
    </figure>
  </xsl:for-each>
  <br/>
  <xsl:value-of select="//project/date"/><br/><br/>
  © 2015-2017 Robert Buj <a href="https://github.com/rbuj/review-translations">https://github.com/rbuj/review-translations</a><br/>
  <br/>
  Copyright (C) 2017 Robert Buj. Permission is granted to copy, distribute and/or modify this document under the terms of the GNU Free Documentation License, Version 1.3 or any later version published by the Free Software Foundation; with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts. A copy of the license is included in the section entitled "GNU Free Documentation License".
</body>
</html>
</xsl:template>
</xsl:stylesheet>
