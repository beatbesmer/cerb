<div style="clear:both;"></div>

{if !empty($subpage) && $subpage instanceof Extension_PageSection}
<div class="cerb-subpage" style="margin-top:5px;">
	{$subpage->render()}
</div>
{/if}
