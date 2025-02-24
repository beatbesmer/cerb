<?php
class WorkspaceWidget_Sheet extends Extension_WorkspaceWidget {
	public function invoke(string $action, Model_WorkspaceWidget $model) {
		$active_worker = CerberusApplication::getActiveWorker();
		
		if(!Context_WorkspaceWidget::isReadableByActor($model, $active_worker))
			DevblocksPlatform::dieWithHttpError(null, 403);
		
		switch($action) {
			case 'renderToolbar':
				return $this->_workspaceWidgetAction_renderToolbar($model);
		}
		
		return false;
	}

	function getData(Model_WorkspaceWidget $widget, $page=null, &$error=null) {
		$data = DevblocksPlatform::services()->data();
		$tpl_builder = DevblocksPlatform::services()->templateBuilder();
		$active_worker= CerberusApplication::getActiveWorker();
		
		@$data_query = DevblocksPlatform::importGPC($widget->params['data_query'], 'string', null);
		@$cache_secs = DevblocksPlatform::importGPC($widget->params['cache_secs'], 'integer', 0);
		
		if($page) {
			$data_query .= sprintf(' page:%d', $page);
		}
		
		$dict = DevblocksDictionaryDelegate::instance([
			'current_worker__context' => CerberusContexts::CONTEXT_WORKER,
			'current_worker_id' => $active_worker->id,
			'widget__context' => CerberusContexts::CONTEXT_WORKSPACE_WIDGET,
			'widget_id' => $widget->id,
		]);
		
		$widget->_loadDashboardPrefsForWorker($active_worker, $dict);
		
		$query = $tpl_builder->build($data_query, $dict);
		
		if(!$query) {
			$error = "Invalid data query.";
			return false;
		}
		
		if(false === ($results = $data->executeQuery($query, [], $error, $cache_secs)))
			return false;
		
		return $results;
	}
	
	function render(Model_WorkspaceWidget $widget) {
		$tpl = DevblocksPlatform::services()->template();
		
		@$page = DevblocksPlatform::importGPC($_POST['page'], 'integer', 0);
		
		$error = null;
		
		if(false == ($results = $this->getData($widget, $page, $error))) {
			echo DevblocksPlatform::strEscapeHtml($error);
			return;
		}
		
		if(empty($results)) {
			echo "(no data)";
			return;
		}
		
		$format = DevblocksPlatform::strLower(@$results['_']['format']);
		
		if(!in_array($format, ['dictionaries'])) {
			echo DevblocksPlatform::strEscapeHtml("The data should be in one of the following formats: dictionaries.");
			return;
		}
		
		switch($format) {
			case 'dictionaries':
				$sheets = DevblocksPlatform::services()->sheet();
				
				@$sheet_kata = DevblocksPlatform::importGPC($widget->params['sheet_kata'], 'string', null);
				
				if(false == ($sheet = $sheets->parse($sheet_kata, $error)))
					$sheet = [];
				
				$sheets->addType('card', $sheets->types()->card());
				$sheets->addType('date', $sheets->types()->date());
				$sheets->addType('icon', $sheets->types()->icon());
				$sheets->addType('link', $sheets->types()->link());
				$sheets->addType('search', $sheets->types()->search());
				$sheets->addType('search_button', $sheets->types()->searchButton());
				$sheets->addType('selection', $sheets->types()->selection());
				$sheets->addType('slider', $sheets->types()->slider());
				$sheets->addType('text', $sheets->types()->text());
				$sheets->addType('time_elapsed', $sheets->types()->timeElapsed());
				$sheets->setDefaultType('text');
				
				$sheet_dicts = $results['data'];
				
				$layout = $sheets->getLayout($sheet);
				$tpl->assign('layout', $layout);
				
				$rows = $sheets->getRows($sheet, $sheet_dicts);
				$tpl->assign('rows', $rows);
				
				$columns = $sheets->getColumns($sheet);
				$tpl->assign('columns', $columns);
				
				@$paging = $results['_']['paging'];
				
				if($layout['paging'] && $paging) {
					$tpl->assign('paging', $paging);
				}
				
				$tpl->assign('widget_ext', $this);
				$tpl->assign('widget', $widget);
				
				if($layout['style'] == 'fieldsets') {
					$tpl->display('devblocks:cerberusweb.core::internal/workspaces/widgets/sheet/render_fieldsets.tpl');
				} else {
					$tpl->display('devblocks:cerberusweb.core::internal/workspaces/widgets/sheet/render.tpl');
				}
				break;
		}
	}
	
	function renderConfig(Model_WorkspaceWidget $widget) {
		$tpl = DevblocksPlatform::services()->template();
		
		if(!array_key_exists('data_query', $widget->params)) {
			$widget->params['data_query'] = "type:worklist.records\nof:ticket\nexpand: [custom_,]\nquery:(\n  status:o\n  limit:10\n  sort:[id]\n)\nformat:dictionaries";
		}
		
		if(!array_key_exists('sheet_kata', $widget->params)) {
			$widget->params['sheet_kata'] = "layout:\n  style: table\n  headings@bool: yes\n  paging@bool: yes\n  #title_column: _label\n\ncolumns:\n  text/id:\n    label: ID\n\n  card/_label:\n    label: Label\n    params:\n      #image@bool: yes\n      #bold@bool: yes\n  ";
		}
		
		$tpl->assign('widget', $widget);
		$tpl->display('devblocks:cerberusweb.core::internal/workspaces/widgets/sheet/config.tpl');
	}
	
	function invokeConfig($action, Model_WorkspaceWidget $model) {
		switch($action) {
			case 'previewToolbar':
				return $this->_workspaceWidgetConfigAction_previewToolbar($model);
		}
	}
	
	function saveConfig(Model_WorkspaceWidget $widget, ?string &$error=null) : bool {
		@$params = DevblocksPlatform::importGPC($_POST['params'], 'array', []);
		
		$kata = DevblocksPlatform::services()->kata();
		
		if(array_key_exists('sheet_kata', $params)) {
			if(false === $kata->validate($params['sheet_kata'], CerberusApplication::kataSchemas()->sheet(), $error)) {
				$error = 'Sheet: ' . $error;
				return false;
			}
		}
		
		if(array_key_exists('toolbar_kata', $params)) {
			if(false === $kata->validate($params['toolbar_kata'], CerberusApplication::kataSchemas()->interactionToolbar(), $error)) {
				$error = 'Toolbar: ' . $error;
				return false;
			}
		}
		
		DAO_WorkspaceWidget::update($widget->id, array(
			DAO_WorkspaceWidget::PARAMS_JSON => json_encode($params),
		));
		
		return true;
	}
	
	private function _workspaceWidgetConfigAction_previewToolbar(Model_WorkspaceWidget $widget) {
		$active_worker = CerberusApplication::getActiveWorker();
		$tpl = DevblocksPlatform::services()->template();
		
		@$toolbar_kata = DevblocksPlatform::importGPC($_POST['params']['toolbar_kata'], 'string', '');
		
		$toolbar_dict = DevblocksDictionaryDelegate::instance([
			'caller_name' => 'cerb.toolbar.workspaceWidget.sheet',
			
			'widget__context' => CerberusContexts::CONTEXT_WORKSPACE_WIDGET,
			'widget_id' => $widget->id,
			
			'worker__context' => CerberusContexts::CONTEXT_WORKER,
			'worker_id' => $active_worker->id,
			
			'row_selections' => [],
		]);
		
		if(false == ($toolbar = DevblocksPlatform::services()->ui()->toolbar()->parse($toolbar_kata, $toolbar_dict)))
			return;
		
		$tpl->assign('toolbar', $toolbar);
		$tpl->display('devblocks:devblocks.core::ui/toolbar/preview.tpl');
	}
	
	function renderToolbar(Model_WorkspaceWidget $widget, $row_selections=[]) {
		$ui = DevblocksPlatform::services()->ui();
		$active_worker = CerberusApplication::getActiveWorker();
		
		$toolbar_dict = DevblocksDictionaryDelegate::instance([
			'caller_name' => 'cerb.toolbar.workspaceWidget.sheet',
			
			'widget__context' => CerberusContexts::CONTEXT_WORKSPACE_WIDGET,
			'widget_id' => $widget->id,
			
			'worker__context' => CerberusContexts::CONTEXT_WORKER,
			'worker_id' => $active_worker->id,
			
			'row_selections' => $row_selections
		]);
		
		if(false != ($toolbar_kata = @$widget->params['toolbar_kata'])) {
			$toolbar = $ui->toolbar()->parse($toolbar_kata, $toolbar_dict);
			
			$ui->toolbar()->render($toolbar);
		}
	}
	
	private function _workspaceWidgetAction_renderToolbar(Model_WorkspaceWidget $widget) {
		@$row_selections = DevblocksPlatform::importGPC($_POST['row_selections'], 'array', []);
		$this->renderToolbar($widget, $row_selections);
	}
};