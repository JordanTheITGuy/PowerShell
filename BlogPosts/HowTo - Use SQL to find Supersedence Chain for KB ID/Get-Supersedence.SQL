--https://portal.msrc.microsoft.com/en-us/security-guidance

DECLARE @KBID int
set @KBID = '4511553'
select SourceKB.Title
	, SourceKB.IsSuperseded
	, SourceKB.InfoURL
	, SupersededList.Title [Supserseded Title]
	, SupersededList.IsSuperseded
	, SupersededList.InfoURL [Supserseded InfoURL]
	, SupersededList.DateCreated [Date Released]
from v_CIRelation_all CA
left join v_UpdateInfo SourceKB on CA.ReferencedCI_ID = SourceKB.CI_ID
left join v_UpdateInfo SupersededList on ca.CI_ID = SupersededList.CI_ID
where RelationType=6 and SourceKB.ArticleID = @KBID

select * from v_CIRelation_All where CI_ID = '16834550'