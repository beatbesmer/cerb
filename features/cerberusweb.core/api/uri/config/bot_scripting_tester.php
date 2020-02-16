<?php
/***********************************************************************
| Cerb(tm) developed by Webgroup Media, LLC.
|-----------------------------------------------------------------------
| All source code & content (c) Copyright 2002-2019, Webgroup Media LLC
|   unless specifically noted otherwise.
|
| This source code is released under the Devblocks Public License.
| The latest version of this license can be found here:
| http://cerb.ai/license
|
| By using this software, you acknowledge having read this license
| and agree to be bound thereby.
| ______________________________________________________________________
|	http://cerb.ai	    http://webgroup.media
***********************************************************************/

class PageSection_SetupDevelopersBotScriptingTester extends Extension_PageSection {
	function render() {
		$visit = CerberusApplication::getVisit();
		$tpl = DevblocksPlatform::services()->template();
		$response = DevblocksPlatform::getHttpResponse();
		
		$stack = $response->path;
		
		@array_shift($stack); // config
		@array_shift($stack); // bot_scripting_tester
		
		$visit->set(ChConfigurationPage::ID, 'bot_scripting_tester');
		
		$tpl->display('devblocks:cerberusweb.core::configuration/section/developers/bot-scripting-tester/index.tpl');
	}
	
	function runScriptAction() {
		@$bot_script = DevblocksPlatform::importGPC($_POST['bot_script'], 'string', null);
		
		if('POST' != DevblocksPlatform::getHttpMethod())
			DevblocksPlatform::dieWithHttpError(403);
		
		$tpl = DevblocksPlatform::services()->template();
		$tpl_builder = DevblocksPlatform::services()->templateBuilder();
		
		header('Content-Type: application/json; charset=utf-8');
		
		$dict = DevblocksDictionaryDelegate::instance([]);
		
		if(false === ($output = $tpl_builder->build($bot_script, $dict))) {
			echo json_encode([
				'status' => false,
				'error' => $tpl_builder->getErrors(),
			]);
			
		} else {
			$tpl->assign('output', $output);
			$html = $tpl->fetch('devblocks:cerberusweb.core::configuration/section/developers/bot-scripting-tester/results.tpl');
			
			echo json_encode([
				'status' => true,
				'html' => $html,
			]);
		}
	}
};