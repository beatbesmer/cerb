<div id="workspaceWidget{$widget->id}Fields">
	<div>
		{if $properties}
			<div class="cerb-fields-container">
			{foreach from=$properties item=v key=k name=props}
				<div class="cerb-fields-container-item">
					{include file="devblocks:cerberusweb.core::internal/custom_fields/profile_cell_renderer.tpl"}
				</div>
			{/foreach}
			</div>
		{/if}

		<div data-cerb-toolbar-container style="margin:5px 0 10px 5px;">
			{if $search_buttons}
				<div class="cerb-search-buttons" style="display:inline;">
					{foreach from=$search_buttons item=search_button}
					<button type="button" class="cerb-search-trigger" data-context="{$search_button.context}" data-query="{$search_button.query}"><div class="badge-count">{$search_button.count|default:0}</div> {$search_button.label|capitalize}</button>
					{/foreach}
				</div>
			{/if}
	
			{if $toolbar_fields}
				<div data-cerb-toolbar style="display:inline-block;">
					{DevblocksPlatform::services()->ui()->toolbar()->render($toolbar_fields)}
				</div>
			{/if}
		</div>
	</div>
	
	{include file="devblocks:cerberusweb.core::internal/custom_fieldsets/profile_fieldsets.tpl" properties=$properties_custom_fieldsets}
	
	{include file="devblocks:cerberusweb.core::internal/profiles/profile_record_links.tpl" properties=$properties_links}
</div>

<script type="text/javascript">
$(function() {
	var $widget = $('#workspaceWidget{$widget->id}Fields');
	var $tab = $widget.closest('.cerb-workspace-layout');
	var $properties = $widget.find('> div:first');
	
	$properties.find('.cerb-peek-trigger').cerbPeekTrigger();
	$properties.find('.cerb-search-trigger').cerbSearchTrigger();

	var $toolbar_container = $widget.find('[data-cerb-toolbar-container]');
	var $toolbar = $toolbar_container.find('[data-cerb-toolbar]');

	$toolbar.cerbToolbar({
		caller: {
			name: 'cerb.toolbar.workspaceWidget.recordFields',
			params: {
				'record__context': '{$dict->_context}',
				'record_id': '{$dict->id}',

				'widget__context': '{CerberusContexts::CONTEXT_WORKSPACE_WIDGET}',
				'widget_id': '{$widget->id}',

				'worker__context': '{CerberusContexts::CONTEXT_WORKER}',
				'worker_id': '{$active_worker->id}'
			}
		},
		start: function(formData) {
			// Include any dynamic params
		},
		done: function(e) {
			e.stopPropagation();

			var $target = e.trigger;

			if(!$target.is('.cerb-bot-trigger'))
				return;

			var done_params = new URLSearchParams($target.attr('data-interaction-done'));

			// Refresh this widget by default
			if(!done_params.has('refresh_widgets[]')) {
				done_params.set('refresh_widgets[]', '{$widget->label}');
			}

			var refresh = done_params.getAll('refresh_widgets[]');

			var widget_ids = [];

			if(-1 !== $.inArray('all', refresh)) {
				// Everything
			} else {
				$tab.find('.cerb-workspace-widget')
					.filter(function() {
						var $this = $(this);
						var name = $this.attr('data-widget-name');

						if(undefined === name)
							return false;

						return -1 !== $.inArray(name, refresh);
					})
					.each(function() {
						var $this = $(this);
						var widget_id = parseInt($this.attr('data-widget-id'));

						if(widget_id)
							widget_ids.push(widget_id);
					})
				;
			}

			var evt = $.Event('cerb-widgets-refresh', {
				widget_ids: widget_ids,
				refresh_options: { }
			});

			$tab.triggerHandler(evt);
		}
	});	
});
</script>