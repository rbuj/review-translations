<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html"/>
<xsl:template match="/">
<html>
<head>
<title>Translation Report</title>
<style>
.menu {
    list-style-type: none;
    white-space:nowrap;
    margin: 0;
    padding: 0;
    background-color: #080808;
    color: #D0D0D0;
}

.menu li a {
    display: block;
    color: #D0D0D0;
    padding: 8px 16px;
    text-decoration: none;
}

.menu li a:hover, .menu li.active a {
    background-color: #D0D0D0;
    color: #080808;
}
</style>
<script type="text/javascript" src="javascript/jquery-JQUERY_VERSION.slim.min.js"></script>
<script>
var make_button_active = function()
{
  var siblings =($(this).siblings());

  siblings.each(function (index)
    {
      $(this).removeClass('active');
    }
  )

  $(this).addClass('active');
}

$(document).ready(
  function()
  {
    $(".menu li").click(make_button_active);
  }
)
</script>
</head>
<body>
<div id="container" style="display: flex; min-height: 100vh;">
    <ul class="menu">
    <xsl:for-each select="components/component">
    <xsl:sort select="name"/>
      <li>
        <a>
          <xsl:attribute name="href">
            <xsl:value-of select="url"/>
          </xsl:attribute>
          <xsl:attribute name="target">main_page</xsl:attribute>
          <xsl:value-of select="name"/>
        </a>
      </li>
    </xsl:for-each>
    </ul>
    <iframe src="data/emty.html" style="flex: 1;" frameBorder="0" name="main_page"></iframe>
</div>
</body>
</html>
</xsl:template>
</xsl:stylesheet>
