{$headers = $message->getHeaders()}
{if !isset($pref_dark_mode)}{$pref_dark_mode = DAO_WorkerPref::get($active_worker->id,'dark_mode',0)}{/if}
{if !isset($always_bright)}{$always_bright = !boolval($pref_dark_mode)}{/if}
{$is_outgoing = $message->is_outgoing}
{$is_not_sent = $message->is_not_sent}

<div class="block" style="margin-bottom:10px;padding-top:8px;padding-left:10px;position:relative;">
	{$sender_id = $message->address_id}
	{$sender = $message->getSender()}
	
	{if $sender}
		{$sender_contact = $sender->getContact()}
		{$sender_worker = $message->getWorker()}

		{if $expanded}
		{$attachments = $message->getAttachments()}
		{else}
		{$attachments = []}
		{/if}

		{if !$embed}
		<div class="toolbar-minmax">
			<button type="button" class="edit cerb-no-print" data-context="{CerberusContexts::CONTEXT_MESSAGE}" data-context-id="{$message->id}" title="Open card popup (Shift+Click to edit)"><span class="glyphicons glyphicons-new-window-alt"></span></button>

			{if $expanded}
				<button type="button" id="{$message->id}skip" class="cerb-no-print" onclick="document.location='#{$message->id}act';" title="{'display.convo.skip_to_bottom'|devblocks_translate}"><span class="glyphicons glyphicons-down-arrow"></span></button>
			{/if}

			{$permalink_url = "{devblocks_url full=true}c=profiles&type=ticket&mask={$ticket->mask}{/devblocks_url}/#message{$message->id}"}
			<button type="button" onclick="genericAjaxPopup('permalink', 'c=internal&a=invoke&module=records&action=showPermalinkPopup&url={$permalink_url|escape:'url'}');" title="{'common.permalink'|devblocks_translate|lower}"><span class="glyphicons glyphicons-link"></span></button>

			{if !$expanded}
				<button id="btnMsgMax{$message->id}" type="button" onclick="genericAjaxGet('message{$message->id}','c=profiles&a=invoke&module=message&action=get&id={$message->id}&widget_id={$widget->id}');" title="{'common.maximize'|devblocks_translate|lower}"><span class="glyphicons glyphicons-resize-full"></span></button>
			{else}
				<button id="btnMsgMin{$message->id}" type="button" onclick="genericAjaxGet('message{$message->id}','c=profiles&a=invoke&module=message&action=get&id={$message->id}&hide=1&widget_id={$widget->id}');" title="{'common.minimize'|devblocks_translate|lower}"><span class="glyphicons glyphicons-resize-small"></span></button>
			{/if}
		</div>
		{/if}

		<div style="display:inline;margin-right:5px;">
			<span class="tag" style="color:white;{if !$is_outgoing}background-color:rgb(185,50,40);{else}background-color:rgb(100,140,25);{/if}">{if $is_outgoing}{if $is_not_sent}{'mail.saved'|devblocks_translate|lower}{else}{'mail.sent'|devblocks_translate|lower}{/if}{else}{'mail.received'|devblocks_translate|lower}{/if}</span>

			{if $message->was_encrypted}
			<span class="tag" style="background-color:rgb(250,220,74);color:rgb(165,100,33);" title="{'common.encrypted'|devblocks_translate|capitalize}"><span class="glyphicons glyphicons-lock"></span></span>
			{/if}
		</div>

		{if $sender_worker}
			<a href="javascript:;" class="cerb-peek-trigger" style="font-size:1.2em;font-weight:bold;" data-context="{CerberusContexts::CONTEXT_WORKER}" data-context-id="{$sender_worker->id}">{if 0 != strlen($sender_worker->getName())}{$sender_worker->getName()}{else}&lt;{$sender_worker->getEmailString()}&gt;{/if}</a>
			&nbsp;
			{if $sender_worker->title}
				{$sender_worker->title}
			{/if}
		{else}
			{if $sender_contact}
				{$sender_org = $sender_contact->getOrg()}
				<a href="javascript:;" class="cerb-peek-trigger" style="font-size:1.2em;font-weight:bold;" data-context="{CerberusContexts::CONTEXT_CONTACT}" data-context-id="{$sender_contact->id}">{$sender_contact->getName()}</a>
				&nbsp;
				{if $sender_contact->title}
					{$sender_contact->title}
				{/if}
				{if $sender_contact->title && $sender_org} at {/if}
				{if $sender_org}
					<a href="javascript:;" class="cerb-peek-trigger no-underline" data-context="{CerberusContexts::CONTEXT_ORG}" data-context-id="{$sender_org->id}"><b>{$sender_org->name}</b></a>
				{/if}
			{else}
				{$sender_org = $sender->getOrg()}
				<a href="javascript:;" class="cerb-peek-trigger" style="font-size:1.2em;font-weight:bold;" data-context="{CerberusContexts::CONTEXT_ADDRESS}" data-context-id="{$sender_id}">&lt;{$sender->email}&gt;</a>
				&nbsp;
				{if $sender_org}
					<a href="javascript:;" class="cerb-peek-trigger no-underline" data-context="{CerberusContexts::CONTEXT_ORG}" data-context-id="{$sender_org->id}"><b>{$sender_org->name}</b></a>
				{/if}
			{/if}
		{/if}

		{if !$message->is_outgoing}
			{if $message->signed_key_fingerprint}
				<span style="margin-left:15px;">
					<span class="glyphicons glyphicons-circle-ok" style="font-size:1.2em;color:rgb(66,131,73);" title="{'common.encrypted.verified'|devblocks_translate|capitalize}"></span>
					Verified
					(<a href="javascript:;" class="cerb-search-trigger" data-context="{Context_GpgPublicKey::ID}" data-query="fingerprint:{$message->signed_key_fingerprint}">{$message->signed_key_fingerprint|substr:-16}</a>)
					{if false && $message->signed_at}
						(<abbr title="{$message->signed_at|devblocks_date}">{$message->signed_at|devblocks_prettytime}</abbr>)
					{/if}
				</span>
			{elseif $message->was_encrypted && !$message->is_outgoing}
				<span style="margin-left:15px;">
					<span class="glyphicons glyphicons-circle-exclamation-mark" style=""></span>
					Unverified
				</span>
			{/if}
		{/if}

		<div style="float:left;margin:0 10px 10px 0;">
			{if $sender_worker}
				<img src="{devblocks_url}c=avatars&context=worker&context_id={$sender_worker->id}{/devblocks_url}?v={$sender_worker->updated}" style="height:48px;width:48px;border-radius:48px;">
			{else}
				{if $sender_contact}
				<img src="{devblocks_url}c=avatars&context=contact&context_id={$sender_contact->id}{/devblocks_url}?v={$sender_contact->updated_at}" style="height:48px;width:48px;border-radius:48px;">
				{else}
				<img src="{devblocks_url}c=avatars&context=address&context_id={$sender->id}{/devblocks_url}?v={$sender->updated}" style="height:48px;width:48px;border-radius:48px;">
				{/if}
			{/if}
		</div>
	{/if}

	<div {if !$embed}id="{$message->id}sh"{/if} style="display:block;margin-top:2px;overflow:hidden;">
		<div style="line-height:1.4em;">
			{if isset($headers.from)}<b>{'message.header.from'|devblocks_translate|capitalize}:</b> {$headers.from|escape|nl2br nofilter}<br>{/if}
			{if isset($headers.to)}<b>{'message.header.to'|devblocks_translate|capitalize}:</b> {$headers.to|escape|nl2br nofilter}<br>{/if}
			{if isset($headers.cc)}<b>{'message.header.cc'|devblocks_translate|capitalize}:</b> {$headers.cc|escape|nl2br nofilter}<br>{/if}
			{if isset($headers.bcc)}<b>{'message.header.bcc'|devblocks_translate|capitalize}:</b> {$headers.bcc|escape|nl2br nofilter}<br>{/if}
			{if isset($headers.subject)}<b>{'message.header.subject'|devblocks_translate|capitalize}:</b> {$headers.subject}<br>{/if}
			<b>{'message.header.date'|devblocks_translate|capitalize}:</b> {$message->created_date|devblocks_date} (<abbr title="{$headers.date}">{$message->created_date|devblocks_prettytime}</abbr>)

			{if !empty($message->response_time)}
				<span style="margin-left:10px;color:var(--cerb-color-email-headers-meta);">Replied in {$message->response_time|devblocks_prettysecs:2}</span>
			{/if}
		</div>

		{if !$expanded}
		<div style="margin-top:0.5em;">
			<div class="cerb-code-editor-toolbar" style="display:inline-block;">
				<button class="cerb-code-editor-toolbar-button" onclick="$('#btnMsgMax{$message->id}').click();"><span class="glyphicons glyphicons-file"></span> Read message ({$message->storage_size|devblocks_prettybytes})</button>
			</div>
		</div>
		{/if}
	</div>

	<div style="clear:both;{if $expanded}margin-bottom:1em;{else}margin-bottom:0.5em;{/if}"></div>

	{if $expanded}
	<div class="cerb-message--content">
		{$filtering_results = null}
		{$html_body = null}

		{if !$display_format}
			{if !DAO_WorkerPref::get($active_worker->id, 'mail_disable_html_display', 0) && $message->html_attachment_id}
				{$html_body = $message->getContentAsHtml($sender->is_trusted, $filtering_results, $pref_dark_mode && !$always_bright)}
			{/if}
		{else}
			{if 'html' == $display_format && $message->html_attachment_id}
				{$html_body = $message->getContentAsHtml($sender->is_trusted, $filtering_results, $pref_dark_mode && !$always_bright)}
			{/if}
		{/if}

		{if $html_body}
			{if !$embed}
			<div class="cerb-code-editor-toolbar" style="margin:0 0 10px 0;display:inline-block;">
				{if $filtering_results && $filtering_results.counts.blockedImage}
					{if !$sender->is_trusted}
					<button type="button" class="cerb-code-editor-toolbar-button" data-cerb-button="display-images" data-message-id="{$message->id}">
						<span class="glyphicons glyphicons-picture"></span>
						Display images
					</button>
					{/if}
					<button type="button" class="cerb-code-editor-toolbar-button" data-cerb-button="email-images" data-message-id="{$message->id}">
						<div class="badge-count badge-red" style="border:0;">{$filtering_results.counts.blockedImage}</div>
						Blocked images
					</button>
				{/if}
				{if $filtering_results && $filtering_results.counts.blockedLink}
					<button type="button" class="cerb-code-editor-toolbar-button" data-cerb-button="email-links" data-message-id="{$message->id}">
						<div class="badge-count badge-red" style="border:0;">{$filtering_results.counts.blockedLink}</div>
						Blocked links
					</button>
				{/if}
				{if $filtering_results && $filtering_results.counts.proxiedImage}
					<button type="button" class="cerb-code-editor-toolbar-button" data-cerb-button="email-images" data-message-id="{$message->id}">
						<div class="badge-count" style="border:0;">{$filtering_results.counts.proxiedImage}</div>
						Images
					</button>
				{/if}
				{if $filtering_results && $filtering_results.counts.redirectedLink}
					<button type="button" class="cerb-code-editor-toolbar-button" data-cerb-button="email-links" data-message-id="{$message->id}">
						<div class="badge-count" style="border:0;">{$filtering_results.counts.redirectedLink}</div>
						Links
					</button>
				{/if}
				{if $pref_dark_mode && !$always_bright}
					<button type="button" class="cerb-code-editor-toolbar-button" data-cerb-button="email-html-light" data-message-id="{$message->id}">
						<span class="glyphicons glyphicons-brightness-increase"></span>
						Bright mode
					</button>
				{/if}
				<button type="button" class="cerb-code-editor-toolbar-button" data-cerb-button="email-plaintext" data-message-id="{$message->id}">
					<span class="glyphicons glyphicons-file"></span>
					View plaintext
				</button>
			</div>
			{/if}
			<div class="{if $always_bright}emailBodyHtmlLight{else}emailBodyHtml{/if}" dir="auto">
				{$html_body nofilter}
			</div>
		{else}
			{if $message->html_attachment_id}
				<div class="cerb-code-editor-toolbar" style="margin:0 0 10px 0;display:inline-block;">
					<button type="button" class="cerb-code-editor-toolbar-button" data-cerb-button="email-html" data-message-id="{$message->id}">
						<span class="glyphicons glyphicons-file"></span>
						View HTML
					</button>
				</div>
			{/if}
			<pre class="emailbody" dir="auto">{$message->getContent()|trim|escape|devblocks_hyperlinks|devblocks_hideemailquotes nofilter}</pre>
		{/if}
		<br>

		{if $active_worker->hasPriv('core.display.actions.attachments.download')}
			{include file="devblocks:cerberusweb.core::internal/attachments/list.tpl" context="{CerberusContexts::CONTEXT_MESSAGE}" context_id=$message->id attachments=$attachments}
		{/if}

		{$values = $message->getCustomFieldValues()}
		{if $values}
        {$message_custom_fields = Page_Profiles::getProfilePropertiesCustomFields(CerberusContexts::CONTEXT_MESSAGE, $values)}
        {$message_custom_fieldsets = Page_Profiles::getProfilePropertiesCustomFieldsets(CerberusContexts::CONTEXT_MESSAGE, $message->id, $values)}
        <div style="margin-top:10px;">
            {if $message_custom_fields}
                <fieldset class="properties" style="padding:5px 0;border:0;">
                    <legend>{'common.properties'|devblocks_translate|capitalize}</legend>

                    <div style="padding:0px 5px;display:flex;flex-flow:row wrap;">
                        {foreach from=$message_custom_fields item=v key=k name=message_custom_fields}
                            <div style="flex:0 0 200px;text-overflow:ellipsis;">
                                {include file="devblocks:cerberusweb.core::internal/custom_fields/profile_cell_renderer.tpl"}
                            </div>
                        {/foreach}
                    </div>
                </fieldset>
            {/if}

            {include file="devblocks:cerberusweb.core::internal/custom_fieldsets/profile_fieldsets.tpl" properties=$message_custom_fieldsets}
        </div>
		{/if}

		{if !$embed}
		<table width="100%" cellpadding="0" cellspacing="0" border="0" class="cerb-no-print">
			<tr>
				<td align="left" id="{$message->id}act">
					{if $widget}
						<div data-cerb-toolbar style="display:inline-block;vertical-align:middle;">
						{* Use pre-expanded dictionaries *}
						{$message_dict = DevblocksDictionaryDelegate::instance([
							'caller_name' => 'cerb.toolbar.mail.read'
						])}
						{$message_dict->mergeKeys('message_', DevblocksDictionaryDelegate::getDictionaryFromModel($message, CerberusContexts::CONTEXT_MESSAGE), null, false, 'message_')}
						{$message_dict->mergeKeys('worker_', DevblocksDictionaryDelegate::getDictionaryFromModel($active_worker, CerberusContexts::CONTEXT_WORKER), null, false, 'worker_')}
						{$message_dict->mergeKeys('widget_', DevblocksDictionaryDelegate::getDictionaryFromModel($widget, CerberusContexts::CONTEXT_PROFILE_WIDGET), null, false, 'widget_')}

						{$toolbar = []}
						{$toolbar_mail_read = DAO_Toolbar::getByName('mail.read')}
						{if $toolbar_mail_read}
							{$toolbar = $toolbar_mail_read->getKata($message_dict)}
						{/if}
							
						{if !array_key_exists('reply', $toolbar) && Context_Ticket::isWriteableByActor($ticket, $active_worker) && $active_worker->hasPriv('core.display.actions.reply')}
							<button type="button" class="reply split-left" title="{if 2 == $mail_reply_button}{'display.reply.only_these_recipients'|devblocks_translate}{elseif 1 == $mail_reply_button}{'display.reply.no_quote'|devblocks_translate}{else}{'display.reply.quote'|devblocks_translate}{/if}"><span class="glyphicons glyphicons-send"></span> {'common.reply'|devblocks_translate|capitalize}</button><!--
						--><button type="button" class="split-right" onclick="$ul=$(this).next('ul');$ul.toggle();if($ul.is(':hidden')) { $ul.blur(); } else { $ul.find('a:first').focus(); }"><span class="glyphicons glyphicons-chevron-down"></span></button>
							<ul class="cerb-popupmenu cerb-float" style="margin-top:-5px;">
								<li><a href="javascript:;" class="cerb-button-reply-quote">{'display.reply.quote'|devblocks_translate}</a></li>
								<li><a href="javascript:;" class="cerb-button-reply-only-these">{'display.reply.only_these_recipients'|devblocks_translate}</a></li>
								<li><a href="javascript:;" class="cerb-button-reply-noquote">{'display.reply.no_quote'|devblocks_translate}</a></li>
								{if $active_worker->hasPriv('core.display.actions.forward')}<li><a href="javascript:;" class="cerb-button-reply-forward">{'display.ui.forward'|devblocks_translate|capitalize}</a></li>{/if}
								<li><a href="javascript:;" class="cerb-button-reply-relay" data-message-id="{$message->id}">Relay to worker email</a></li>
							</ul>
						{/if}

						{if !array_key_exists('comment', $toolbar) && $active_worker->hasPriv('contexts.cerberusweb.contexts.message.comment')}
							<button type="button" class="cerb-sticky-trigger" data-context="{CerberusContexts::CONTEXT_COMMENT}" data-context-id="0" data-edit="context:{CerberusContexts::CONTEXT_MESSAGE} context.id:{$message->id}" title="{'common.comment'|devblocks_translate|capitalize}"><span class="glyphicons glyphicons-comments"></span> {'display.ui.sticky_note'|devblocks_translate|capitalize}</button>
						{/if}

						{DevblocksPlatform::services()->ui()->toolbar()->render($toolbar)}
						</div>

						<script type="text/javascript">
							$(function() {
								var $toolbar = $('#{$message->id}act').find('[data-cerb-toolbar]');
								var $profile_tab = $toolbar.closest('.cerb-profile-layout');

								var doneFunc = function(e) {
									e.stopPropagation();

									var $target = e.trigger;

									if(!$target.is('.cerb-bot-trigger'))
										return;

									var done_params = new URLSearchParams($target.attr('data-interaction-done'));

									if(e.eventData.hasOwnProperty('return') 
										&& e.eventData.return.hasOwnProperty('reply') 
										&& e.eventData.return.reply.hasOwnProperty('draft_id')) {
										
										var msg_id = '{$message->id}';
										var is_forward = '0';
										var draft_id = e.eventData.return.reply.draft_id;
										var reply_mode = '0';

										var formData = new FormData();
										formData.set('c', 'profiles');
										formData.set('a', 'invoke');
										formData.set('module', 'ticket');
										formData.set('action', 'reply');
										formData.set('forward', is_forward);
										formData.set('draft_id', draft_id);
										formData.set('reply_mode', reply_mode);
										formData.set('timestamp', '{time()}');
										formData.set('id', msg_id);

										var $popup_reply = genericAjaxPopup('reply' + msg_id, formData, null, false, '80%');

										$popup_reply.on('cerb-reply-sent cerb-reply-saved cerb-reply-draft', function(json) {
											var evt = $.Event('cerb-widgets-refresh', {
												widget_ids: [{$widget->id}],
												refresh_options: { }
											});

											$profile_tab.triggerHandler(evt);
										});
									}

									if(!done_params.has('refresh_widgets[]'))
										return;

									var refresh = done_params.getAll('refresh_widgets[]');

									var widget_ids = [];

									if(-1 !== $.inArray('all', refresh)) {
										// Everything
									} else {
										$profile_tab.find('.cerb-profile-widget')
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

									$profile_tab.triggerHandler(evt);
								};

								$toolbar.cerbToolbar({
									caller: {
										name: 'cerb.toolbar.mail.read',
										params: {
											message_id: '{$message->id}',
											selected_text: '' 
										}
									},
									start: function(formData) {
										formData.set('caller[params][selected_text]', document.getSelection());
									},
									done: doneFunc
								});
							});
						</script>
					{/if}

					<button type="button" onclick="$('#{$message->id}options').toggle();" title="{'common.more'|devblocks_translate|capitalize}"><span class="glyphicons glyphicons-more"></span></button>

					<form id="{$message->id}options" style="padding-top:10px;display:none;" method="post" action="{devblocks_url}{/devblocks_url}">
						<input type="hidden" name="c" value="profiles">
						<input type="hidden" name="a" value="invoke">
						<input type="hidden" name="module" value="ticket">
						<input type="hidden" name="action" value="">
						<input type="hidden" name="id" value="{$message->id}">
						<input type="hidden" name="_csrf_token" value="{$session.csrf_token}">

						{* If not requester *}
						{if !$message->is_outgoing && !isset($requesters.{$sender_id})}
							<button data-cerb-button="requester-add"><span class="glyphicons glyphicons-circle-plus"></span> {'display.ui.add_to_recipients'|devblocks_translate}</button>
						{/if}

						<button type="button" onclick="genericAjaxPopup('message_headers','c=profiles&a=invoke&module=ticket&action=showMessageFullHeadersPopup&id={$message->id}');"><span class="glyphicons glyphicons-envelope"></span> {'message.headers'|devblocks_translate|capitalize}</button>

						{if $ticket->first_message_id != $message->id && $active_worker->hasPriv('core.display.actions.split')} {* Don't allow splitting of a single message *}
							<button type="button" onclick="$frm=$(this).closest('form');$frm.find('input:hidden[name=action]').val('splitMessage');$frm.submit();" title="Split message into new ticket"><span class="glyphicons glyphicons-duplicate"></span> {'display.button.split_ticket'|devblocks_translate|capitalize}</button>
						{/if}

						{if $message->is_outgoing}
							<button type="button" onclick="genericAjaxPopup('message_resend','c=profiles&a=invoke&module=ticket&action=showResendMessagePopup&id={$message->id}');"><span class="glyphicons glyphicons-share"></span> Send Again</button>
						{/if}
						
						{if $attachments && extension_loaded('zip')}
						<button type="button" data-cerb-download-all><span class="glyphicons glyphicons-download"></span> Download all (.zip)</button>
						{/if}
					</form>
				</td>
			</tr>
		</table>
		{/if}

		{if !$embed}
		<div id="{$message->id}b"></div>
		<div id="{$message->id}notes" class="cerb-comments-thread">
			{include file="devblocks:cerberusweb.core::display/modules/conversation/notes.tpl"}
		</div>
		{/if}
	</div> <!-- end visible -->
	{/if}
</div>

{if !$embed}
<div id="reply{$message->id}"></div>
{/if}

{if !$embed}
<script type="text/javascript">
$(function() {
	var $msg = $('#message{$message->id}').unbind();
	
	$msg.hover(
		function() {
			$msg.find('div.toolbar-minmax').show();
		},
		function() {
			$msg.find('div.toolbar-minmax').hide();
		}
	);
	
	$msg.find('.cerb-search-trigger')
		.cerbSearchTrigger()
		;
	
	try {
		if($('#{$message->id}act').visible()) {
			$('#{$message->id}skip').hide();
		}
	} catch(e) {
	}
});
</script>
{/if}

{if !$embed && $active_worker->hasPriv('core.display.actions.reply')}
<script type="text/javascript">
$(function() {
	var $msg = $('#message{$message->id}');
	var $actions = $('#{$message->id}act');
	var $notes = $('#{$message->id}notes');
	
	$msg.find('.cerb-peek-trigger')
		.cerbPeekTrigger()
		;

	$msg.find('.cerb-sticky-trigger')
		.cerbPeekTrigger()
			.on('cerb-peek-saved', function(e) {
				e.stopPropagation();
				
				if(e.id && e.comment_html) {
					var $new_note = $('<div id="comment' + e.id + '"/>')
						.addClass('cerb-comments-thread--comment')
						.hide()
					;
					$new_note.html(e.comment_html).prependTo($notes).fadeIn();
				}
			})
			;
	
	// Peek
	
	$msg.find('button.edit')
		.cerbPeekTrigger()
		.on('cerb-peek-opened', function(e) {
		})
		.on('cerb-peek-saved', function(e) {
			e.stopPropagation();
			genericAjaxGet('message{$message->id}','c=profiles&a=invoke&module=message&action=get&id={$message->id}&hide=0&widget_id={$widget->id}');
		})
		.on('cerb-peek-deleted', function(e) {
			e.stopPropagation();
			$('#message{$message->id}').remove();
		})
		;

	$msg.find('[data-cerb-button=email-plaintext]').on('click', function(e) {
		e.stopPropagation();
		genericAjaxGet('message{$message->id}','c=profiles&a=invoke&module=message&action=get&id={$message->id}&format=text&widget_id={$widget->id}');
	});

	$msg.find('[data-cerb-button=email-html]').on('click', function(e) {
		e.stopPropagation();
		genericAjaxGet('message{$message->id}','c=profiles&a=invoke&module=message&action=get&id={$message->id}&format=html&widget_id={$widget->id}');
	});

	$msg.find('[data-cerb-button=email-html-light]').on('click', function(e) {
		e.stopPropagation();
		genericAjaxGet('message{$message->id}','c=profiles&a=invoke&module=message&action=get&id={$message->id}&format=html&light=1&widget_id={$widget->id}');
	});

	$msg.find('[data-cerb-button=display-images]').on('click', function(e) {
		e.stopPropagation();
		genericAjaxGet('message{$message->id}','c=profiles&a=invoke&module=message&action=get&id={$message->id}&images=1&widget_id={$widget->id}');
	});

	$msg.find('[data-cerb-button=email-images]').on('click', function(e) {
		e.stopPropagation();

		var $button = $(this);
		var message_id = $button.attr('data-message-id');

		var formData = new FormData();
		formData.set('c', 'profiles');
		formData.set('a', 'invoke');
		formData.set('module', 'message');
		formData.set('action', 'renderImagesPopup');
		formData.set('id', message_id);
		formData.set('type', 'images');

		var $popup_filtering = genericAjaxPopup('emailFiltering', formData, null, false);

		$popup_filtering.on('cerb-message--show-images', function(e) {
			e.stopPropagation();
			genericAjaxGet('message{$message->id}','c=profiles&a=invoke&module=message&action=get&id={$message->id}&images=1&widget_id={$widget->id}');
		});

		$popup_filtering.on('popup_saved', function(e) {
			e.stopPropagation();
			genericAjaxGet('message{$message->id}','c=profiles&a=invoke&module=message&action=get&id={$message->id}&widget_id={$widget->id}');
		});
	});

	$msg.find('[data-cerb-button=email-links]').on('click', function(e) {
		e.stopPropagation();

		var $button = $(this);
		var message_id = $button.attr('data-message-id');

		var formData = new FormData();
		formData.set('c', 'profiles');
		formData.set('a', 'invoke');
		formData.set('module', 'message');
		formData.set('action', 'renderLinksPopup');
		formData.set('id', message_id);

		var $popup_filtering = genericAjaxPopup('emailFiltering', formData, null, false);

		$popup_filtering.on('popup_saved', function(e) {
			e.stopPropagation();
			genericAjaxGet('message{$message->id}','c=profiles&a=invoke&module=message&action=get&id={$message->id}&widget_id={$widget->id}');
		});
	});
	
	$msg.find('[data-cerb-download-all]').on('click', function(e) {
		e.stopPropagation();

		var a = document.createElement('a');
		a.style = 'display: none';
		document.body.appendChild(a);
		a.href = '{devblocks_url}c=files&a=message&id={$message->id}{/devblocks_url}';
		a.click();
		a.remove();
	});

	$actions.find('[data-cerb-button=requester-add]').on('click', function() {
		$(this).remove();

		var formData = new FormData();
		formData.set('c', 'profiles');
		formData.set('a', 'invoke');
		formData.set('module', 'ticket');
		formData.set('action', 'requesterAdd');
		formData.set('ticket_id', '{$ticket->id}');
		formData.set('email', '{$sender->email}');

		genericAjaxPost(formData, null, null);
	});
	
	$actions
		.find('ul.cerb-popupmenu')
		.hover(
			function(e) { }, 
			function(e) { $(this).hide(); }
		)
		.find('> li')
		.click(function(e) {
			$(this).closest('ul.cerb-popupmenu').hide();
	
			e.stopPropagation();
			if(!$(e.target).is('li'))
			return;
	
			$(this).find('a').trigger('click');
		})
		;
	
	$actions.find('button.reply')
		.on('click', function(e) {
			if(e.originalEvent && e.originalEvent.detail && e.originalEvent.detail > 1)
				return;
			
			var evt = $.Event('cerb_reply');
			evt.message_id = '{$message->id}';
			evt.is_forward = 0;
			evt.draft_id = 0;
			evt.reply_mode = '{$mail_reply_button}';
			
			$msg.trigger(evt);
		})
		;
	
	$actions.find('a.cerb-button-reply-quote')
		.on('click', function(e) {
			if(e.originalEvent && e.originalEvent.detail && e.originalEvent.detail > 1)
				return;
			
			var evt = $.Event('cerb_reply');
			evt.message_id = '{$message->id}';
			evt.is_forward = 0;
			evt.draft_id = 0;
			evt.reply_mode = 0;
			
			$msg.trigger(evt);
		})
		;
	
	$actions.find('a.cerb-button-reply-only-these')
		.on('click', function(e) {
			if(e.originalEvent && e.originalEvent.detail && e.originalEvent.detail > 1)
				return;
			
			var evt = $.Event('cerb_reply');
			evt.message_id = '{$message->id}';
			evt.is_forward = 0;
			evt.draft_id = 0;
			evt.reply_mode = 2;
			
			$msg.trigger(evt);
		})
		;
	
	$actions.find('a.cerb-button-reply-noquote')
		.on('click', function(e) {
			if(e.originalEvent && e.originalEvent.detail && e.originalEvent.detail > 1)
				return;
			
			var evt = $.Event('cerb_reply');
			evt.message_id = '{$message->id}';
			evt.is_forward = 0;
			evt.draft_id = 0;
			evt.reply_mode = 1;
			
			$msg.trigger(evt);
		})
		;
	
	$actions.find('a.cerb-button-reply-forward')
		.on('click', function(e) {
			if(e.originalEvent && e.originalEvent.detail && e.originalEvent.detail > 1)
				return;
			
			var evt = $.Event('cerb_reply');
			evt.message_id = '{$message->id}';
			evt.is_forward = 1;
			evt.draft_id = 0;
			evt.reply_mode = 0;
			
			$msg.trigger(evt);
		})
		;
	
	$actions.find('a.cerb-button-reply-relay')
		.on('click', function() {
			genericAjaxPopup('relay', 'c=profiles&a=invoke&module=message&action=showRelayMessagePopup&id={$message->id}', null, false, '50%');
		})
		;
	});
</script>
{/if}