{$is_selection_enabled = false}

<div class="cerb-sheet-layout {if $layout_style == 'columns'}cerb-sheet-columns{else}cerb-sheet-grid{/if}">
	{if $rows}
	{foreach from=$rows item=row name=rows}
	<div class="cerb-sheet--row" {if $layout_style == 'grid' && $layout.params.width}style="flex:1 1 {$layout.params.width|round}px;"{/if}>
		<div class="cerb-sheet--row-item">
		{foreach from=$columns item=column name=columns}
			<div data-cerb-column-type="{$column._type}">
			{if $column._type == 'selection'}
				{$is_selection_enabled = true}
				{$row[$column.key]|replace:'${SHEET_SELECTION_KEY}':{$sheet_selection_key|default:'_selection'} nofilter}
			{else}
				{if $column.params.bold}<span style="font-weight:bold;">{/if}
				{$row[$column.key] nofilter}
				{if $column.params.bold}</span>{/if}
			{/if}
			</div>
		{/foreach}
		</div>
	</div>
	{/foreach}
	{/if}
</div>

{if $paging && $paging.page.of > 1}
	<span style="float:right;margin-top:5px;">
		{if array_key_exists('first', $paging.page)}<a href="javascript:;" class="cerb-paging" data-page="{$paging.page.first}">&lt;&lt;</a>{/if}
		{if array_key_exists('prev', $paging.page)}<a href="javascript:;" class="cerb-paging" data-page="{$paging.page.prev}">&lt;{'common.previous_short'|devblocks_translate|capitalize}</a>{/if}
		(Showing {if $paging.page.rows.from==$paging.page.rows.to}{$paging.page.rows.from}{else}{$paging.page.rows.from}-{$paging.page.rows.to}{/if}
		 of {$paging.page.rows.of})
		{if array_key_exists('next', $paging.page)}<a href="javascript:;" class="cerb-paging" data-page="{$paging.page.next}">{'common.next'|devblocks_translate|capitalize}&gt;</a>{/if}
		{if array_key_exists('last', $paging.page)}<a href="javascript:;" class="cerb-paging" data-page="{$paging.page.last}">&gt;&gt;</a>{/if}
	</span>
{/if}

{$script_uid = uniqid('script')}
<script type="text/javascript" id="{$script_uid}">
$(function() {
	var $script = $('#{$script_uid}');
	var $sheet = $script.siblings('div.cerb-sheet-layout');

	$sheet.find('.cerb-peek-trigger')
		.cerbPeekTrigger()
		.on('cerb-peek-saved cerb-peek-deleted', function(e) {
			e.stopPropagation();
			$sheet.trigger($.Event('cerb-sheet--refresh'));
		})
	;

	$sheet.find('.cerb-search-trigger')
		.cerbSearchTrigger()
	;

	$sheet.parent().find('.cerb-paging')
		.click(function() {
			var $this = $(this);
			var page = $this.attr('data-page');

			if(null == page)
				return;

			var evt = $.Event('cerb-sheet--page-changed', { page: page });
			$sheet.trigger(evt);
		})
	;

	{if $is_selection_enabled}
	$sheet.find('div.cerb-sheet--row')
		.disableSelection()
		.on('click', function(e) {
			e.stopPropagation();
			e.preventDefault();

			var $target = $(e.target);
			var evt;

			if($target.is('a'))
				return;

			if($target.hasClass('cerb-peek-trigger'))
				return;

			if($target.hasClass('cerb-search-trigger'))
				return;

			var $tbody = $(this);

			var $checkbox = $tbody.find('input[type=radio], input[type=checkbox]');

			// If our target was something other than the input toggle
			if($checkbox.is($target))
				return;
			
			if($checkbox.is(':checked')) {
				$checkbox.prop('checked', false);
			} else {
				$checkbox.prop('checked', true);
			}

			var is_multiple = $checkbox.is('[type=checkbox]');
			
			var $row = $target.closest('.cerb-sheet--row');
			
			// Uncheck everything if single selection
			if(!is_multiple) {
				$row.closest('.cerb-sheet-layout').find('.cerb-sheet--row').removeClass('cerb-sheet--row-selected');
			}

			if($checkbox.is(':checked')) {
				$row.addClass('cerb-sheet--row-selected');
			} else if (is_multiple) {
				$row.removeClass('cerb-sheet--row-selected')
			}
			
			evt = $.Event('cerb-sheet--selection', 
				{
					ui: { 
						item: $checkbox 
					}, 
					is_multiple: is_multiple,
					selected: $checkbox.prop('checked')
				}
			);
			$sheet.trigger(evt);

			var row_selections = [];

			$tbody.closest('table.cerb-sheet')
				.find('input[type=radio]:checked ,input[type=checkbox]:checked')
				.each(function() {
					row_selections.push($(this).val());
				})
				;

			evt = $.Event('cerb-sheet--selections-changed', { row_selections: row_selections, is_multiple: is_multiple });
			$sheet.trigger(evt);
		})
		.hover(
			function(e) {
				e.stopPropagation();
				$(this).addClass('hover');
			},
			function(e) {
				e.stopPropagation();
				$(this).removeClass('hover');
			}
		)
	;
	{/if}
});
</script>