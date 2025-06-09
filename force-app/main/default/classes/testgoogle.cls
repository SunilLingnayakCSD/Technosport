public class testgoogle {
public static String buildPublicUrl(ContentVersion cVersion, ContentDistribution cDist) {
    String fileType = cVersion.FileType.toLowerCase().capitalize();
    String cVersionId = cVersion.Id;
    String cBodyId = cVersion.ContentBodyId;
    String originalUrl = String.valueOf(cDist.DistributionPublicUrl);
    String cDistParam = originalUrl.substring(originalUrl.indexOf('/a/'));
    String orgId = ConnectApi.Organization.getSettings().orgId;
    String baseDomain = Url.getOrgDomainUrl().toExternalForm();
    baseDomain = baseDomain.substringBefore('.') + '--c.documentforce.com';
    String theUrl = baseDomain + '/sfc/dist/version/renditionDownload?rendition=ORIGINAL_' +
            fileType + '&versionId=' + cVersionId + '&operationContext=DELIVERY&contentId=' + cBodyId +
            '&page=0&d=' + cDistParam + '&oid=' + orgId + '&dpt=null&viewId=';
    return theUrl;
}
}