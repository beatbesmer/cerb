<?php
namespace Cerb\AutomationBuilder\Action;

use DevblocksDictionaryDelegate;
use DevblocksPlatform;
use Exception_DevblocksAutomationError;
use Model_Automation;

class QueuePushAction extends AbstractAction {
	const ID = 'queue.push';
	
	function activate(Model_Automation $automation, DevblocksDictionaryDelegate $dict, array &$node_memory, string &$error=null) {
		$validation = DevblocksPlatform::services()->validation();
		$queue = DevblocksPlatform::services()->queue();
		
		$params = $this->node->getParams($dict);
		$policy = $automation->getPolicy();
		
		$inputs = $params['inputs'] ?? [];
		$output = $params['output'] ?? null;
		
		try {
			// Validate params
			
			$validation->addField('inputs', 'inputs:')
				->array()
				;
			
			$validation->addField('output', 'output:')
				->string()
				->setRequired(true)
				;
			
			if(false === ($validation->validateAll($params, $error)))
				throw new Exception_DevblocksAutomationError($error);
			
			// Validate input
			
			$validation->reset();
			
			$validation->addField('queue_name', 'inputs:queue_name:')
				->string()
				->setRequired(true)
				;
			
			$validation->addField('messages', 'inputs:messages:')
				->array()
				->setRequired(true)
				;
			
			if(false === ($validation->validateAll($inputs, $error)))
				throw new Exception_DevblocksAutomationError($error);
				
			$queue_name = $inputs['queue_name'];
			$messages = $inputs['messages'];
			
			$action_dict = DevblocksDictionaryDelegate::instance([
				'node' => [
					'id' => $this->node->getId(),
					'type' => self::ID,
				],
				'inputs' => $inputs,
				'output' => $output,
			]);
			
			if(!$policy->isCommandAllowed(self::ID, $action_dict)) {
				$error = sprintf(
					"The automation policy does not allow this command (%s).",
					self::ID
				);
				throw new Exception_DevblocksAutomationError($error);
			}
			
			if(false == ($results = $queue->enqueue($queue_name, $messages, $error))) {
				throw new Exception_DevblocksAutomationError($error);
			}
			
			// Set output
			
			if($output) {
				$dict->set($output, $results);
			}
			
		} catch (Exception_DevblocksAutomationError $e) {
			$error = $e->getMessage();
			
			if(null != ($event_error = $this->node->getChildBySuffix(':on_error'))) {
				$dict->set($output, [
					'error' => $error,
				]);
				
				return $event_error->getId();
			}
			
			return false;
		}
		
		if(null != ($event_success = $this->node->getChild($this->node->getId() . ':on_success'))) {
			return $event_success->getId();
		}
		
		return $this->node->getParent()->getId();
	}
}