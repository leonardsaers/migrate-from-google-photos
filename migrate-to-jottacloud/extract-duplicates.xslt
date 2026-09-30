<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Släpp ut ren text, ingen XML-header -->
    <xsl:output method="text" encoding="UTF-8"/>
    <xsl:strip-space elements="*"/>

    <!-- 
      1. HASHTABELL / INDEX
      Indexera alla filer i mobil-backupen (photos) baserat på: År/Månad/Filnamn.
      Detta bygger en O(1) hashtabell i minnet.
    -->
    <xsl:key name="backup-files" 
             match="photos/year/month/file" 
             use="concat(../../@value, '/', ../@value, '/', @name)" />

    <!-- 
      2. ROTMALL
      Startar transformeringen.
    -->
    <xsl:template match="/">
        <xsl:apply-templates select="jottacloud/google-photos"/>
    </xsl:template>

    <!-- 
      3. STRUKTURMALLAR
      Låt år och månad bara släppa igenom sina undernoder.
    -->
    <xsl:template match="google-photos | year | month">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- 
      4. FIL-MALL (Kärnlogiken)
      Matas med filer från google-photos. Matchar mot hashtabellen.
    -->
    <xsl:template match="google-photos//file">
        <!-- Skapa samma nyckel baserat på filens egen År/Månad/Namn-kontext -->
        <xsl:variable name="current-key" 
                      select="concat(../../@value, '/', ../@value, '/', @name)" />

        <!-- Slå upp i hashtabellen om filen finns minst 2 gånger i photos -->
        <xsl:if test="count(key('backup-files', $current-key)) &gt; 1">
            <xsl:value-of select="@path"/>
            <xsl:text>&#10;</xsl:text>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>