<?php
class _DevblocksDataProviderWorklistGeoPoints extends _DevblocksDataProvider {
	function getSuggestions($type, array $params=[]) {
		return [
			'' => [
				[
					'caption' => 'series:',
					'snippet' => "series.\${1:alias}:(\n  of:\${2:org}\n  point:\${3:coordinates}\n  fields:[\${4:name,coordinates}]\n  query:(\n    \${5:coordinates:!null}\n  )\n)",
					'suppress_autocomplete' => true,
				],
				'timeout:',
				'format:',
			],
			'series.*:' => [
				'' => [
					'of:',
					[
						'caption' => 'point:',
						'snippet' => 'point:${1:coordinates}',
					],
					[
						'caption' => 'fields:',
						'snippet' => 'fields:[${1:name,coordinates}]',
					],
					[
						'caption' => 'query:',
						'snippet' => 'query:(${1})',
					],
					[
						'caption' => 'query.required:',
						'snippet' => 'query.required:(${1})',
					],
				],
				'of:' => array_values(Extension_DevblocksContext::getUris()),
				'point:' => [
					'_type' => 'series_of_field',
					'of_types' => 'geo_point',
				],
				'fields:' => [
					'_type' => 'series_of_field',
				],
				'query:' => [
					'_type' => 'series_of_query',
				],
				'query.required:' => [
					'_type' => 'series_of_query',
				],
			],
			'format:' => [
				'geojson',
				'table',
				//'dictionaries', // [TODO]
			]
		];
	}
	
	function getData($query, $chart_fields, &$error=null, array $options=[]) {
		$db = DevblocksPlatform::services()->database();
		
		$chart_model = [
			'type' => 'worklist.geo.points',
			'series' => [],
			'timeout' => 20000,
			'format' => 'geojson',
		];
		
		foreach($chart_fields as $field) {
			$oper = $value = null;
			
			if(!($field instanceof DevblocksSearchCriteria))
				continue;
			
			if($field->key == 'type') {
				// Do nothing
				true;
				
			} else if($field->key == 'format') {
				CerbQuickSearchLexer::getOperStringFromTokens($field->tokens, $oper, $value);
				$chart_model['format'] = $value;
				
			} else if($field->key == 'timeout') {
				CerbQuickSearchLexer::getOperStringFromTokens($field->tokens, $oper, $value);
				$chart_model['timeout'] = DevblocksPlatform::intClamp($value, 0, 60000);

			} else if(DevblocksPlatform::strStartsWith($field->key, 'series.')) {
				$series_query = CerbQuickSearchLexer::getTokensAsQuery($field->tokens);
				$series_query = substr($series_query, 1, -1);
				
				$series_fields = CerbQuickSearchLexer::getFieldsFromQuery($series_query);
				
				$series_id = explode('.', $field->key, 2)[1];
				
				$series_model = [
					'id' => $series_id,
					'label' => $series_id,
					'context' => '',
					'point' => '',
					'fields' => [],
					'query' => '',
					'data' => [],
				];
				
				$series_context = null;
				
				foreach($series_fields as $series_field) {
					if(in_array($series_field->key, ['point'])) {
						// Do nothing
						true;
						
					} else if($series_field->key == 'of') {
						CerbQuickSearchLexer::getOperStringFromTokens($series_field->tokens, $oper, $value);
						if(false == ($series_context = Extension_DevblocksContext::getByAlias($value, true)))
							continue;
						
						$series_model['context'] = $series_context->id;
						
					} else if($series_field->key == 'fields') {
						CerbQuickSearchLexer::getOperArrayFromTokens($series_field->tokens, $oper, $value);
						$series_model['fields'] = $value;
						
					} else if($series_field->key == 'query') {
						$data_query = CerbQuickSearchLexer::getTokensAsQuery($series_field->tokens);
						$data_query = substr($data_query, 1, -1);
						$series_model['query'] = $data_query;
						
					} else if(in_array($series_field->key, ['query.require','query.required'])) {
						$data_query = CerbQuickSearchLexer::getTokensAsQuery($series_field->tokens);
						$data_query = substr($data_query, 1, -1);
						$series_model['query_required'] = $data_query;
						
					} else {
						$error = sprintf("The series parameter '%s' is unknown.", $series_field->key);
						return false;
					}
				}
				
				// Convert series to SearchFields_* using context
				
				$has_geopoint_field = false;
				
				if($series_context) {
					$view = $series_context->getTempView();
					$search_class = $series_context->getSearchClass();
					$query_fields = $view->getQuickSearchFields();
					$search_fields = $view->getFields();
					
					if(array_key_exists('fields', $series_model)) {
						$fields = $series_model['fields'];
						unset($series_model['fields']);
						
						foreach($fields as $field_key) {
							if(false != ($field = $search_class::getFieldForSubtotalKey($field_key, $series_context->id, $query_fields, $search_fields, $search_class::getPrimaryKey()))) {
								if(!$has_geopoint_field && $field['type'] == CustomField_GeoPoint::ID) {
									$has_geopoint_field = true;
									$series_model['point'] = $field;
								}
								
								$series_model['fields'][] = $field;
							}
						}
					}
					
					if(!$has_geopoint_field) {
						$error = 'The series `fields:` list must contain at least one geopoint field.';
						return false;
					}
				}
				
				$chart_model['series'][] = $series_model;
				
			} else {
				$error = sprintf("The parameter '%s' is unknown.", $field->key);
				return false;
			}
		}
		
		// Fetch data
		
		if(isset($chart_model['series']))
		foreach($chart_model['series'] as $series_idx => $series) {
			if(!isset($series['context']))
				continue;
			
			@$query = $series['query'];
			@$query_required = $series['query_required'];
			
			$context_ext = Extension_DevblocksContext::get($series['context'], true);
			$dao_class = $context_ext->getDaoClass();
			$view = $context_ext->getTempView();
			
			if(false === $view->addParamsRequiredWithQuickSearch($query_required, true, [], $error))
				return false;
				
			if(false === $view->addParamsWithQuickSearch($query, true, [], $error))
				return false;
			
			$query_parts = $dao_class::getSearchQueryComponents(
				[],
				$view->getParams()
			);
			
			$sql = sprintf("SELECT %s %s %s LIMIT %d",
				implode(', ', array_map(function($e) use ($db) {
					return sprintf("%s AS `%s`",
						$e['sql_select'],
						$db->escape($e['key_select'])
					);
				}, $series['fields'])),
				$query_parts['join'],
				$query_parts['where'],
				$view->renderLimit
			);
			
			try {
				if(false == ($results = $db->GetArrayReader($sql, $chart_model['timeout'])))
					$results = [];
				
			} catch (Exception_DevblocksDatabaseQueryTimeout $e) {
				$error = sprintf('Query timed out (%d ms)', $chart_model['timeout']);
				return false;
			}
			
			$key_map = [];
			$data = [];
			
			foreach($series['fields'] as $field)
				$key_map[$field['key_select']] = $field['key_query'];
			
			foreach($results as $result) {
				$data[] = array_combine($key_map, $result);
			}
			
			$chart_model['series'][$series_idx]['data'] = $data;
		}
		
		// Respond
		
		@$format = $chart_model['format'] ?: 'geojson';
		
		switch($format) {
			case 'geojson':
				return $this->_formatDataAsGeoJson($chart_model);
				
			case 'table':
				return $this->_formatDataAsTable($chart_model);
			
			case 'topojson':
				return $this->_formatDataAsTopoJson($chart_model);
				
			default:
				$error = sprintf("`format:%s` is not valid for `type:%s`. Must be one of: geojson, table",
					$format,
					$chart_model['type']
				);
				return false;
		}
	}
	
	function _formatDataAsGeoJson($chart_model) {
		$points = [
			'type' => 'FeatureCollection',
			'features' => [],
		];
		
		if(array_key_exists('series', $chart_model))
		foreach($chart_model['series'] as $series) {
			$series_label = $series['label'];
			
			foreach($series['data'] as $row) {
				$point = @DevblocksPlatform::parseGeoPointString($row[$series['point']['key_query']]);
				
				$properties = $row;
				$properties['cerb_series'] = $series_label;
				
				$points['features'][] = [
					'type' => 'Feature',
					'geometry' => [
						'type' => 'Point',
						'coordinates' => [
							$point['longitude'], // long
							$point['latitude'], // lat
						],
					],
					'properties' => $properties,
				];
			}
		}
		
		return [
			'data' => $points,
			'_' => [
				'type' => 'worklist.geo.points',
				'format' => 'geojson',
			]
		];
	}
	
	function _formatDataAsTopoJson($chart_model) {
		$points = [
			'type' => 'Topology',
			'objects' => [],
		];
		
		if(array_key_exists('series', $chart_model))
		foreach($chart_model['series'] as $series) {
			$series_label = $series['label'];
			
			$points['objects'][$series_label] = [
				'type' => 'GeometryCollection',
				'geometries' => [],
			];
			
			foreach($series['data'] as $row) {
				$point = @DevblocksPlatform::parseGeoPointString($row[$series['point']['key_query']]);
				
				$properties = $row;
				
				$points['objects'][$series_label]['geometries'][] = [
					'type' => 'Point',
					'coordinates' => [
						$point['longitude'], // long
						$point['latitude'], // lat
					],
					'properties' => $properties,
				];
			}
		}
		
		return [
			'data' => $points,
			'_' => [
				'type' => 'worklist.geo.points',
				'format' => 'topojson',
			]
		];
	}
	
	function _formatDataAsTable($chart_model) {
		$rows = $columns = [];
		
		$table = [
			'columns' => &$columns,
			'rows' => &$rows,
		];

		$series_models = $chart_model['series'];
		
		foreach($series_models as $series_idx => $series) {
			if(0 == $series_idx) {
				foreach($series['fields'] as $field) {
					$columns[$field['key_query']] = [
						'label' => DevblocksPlatform::strTitleCase($field['label']),
						'type' => $field['type'],
						'type_options' => @$field['type_options'] ?: [],
					];
				}
			}
			
			foreach($series['data'] as $row) {
				$point_key = $series['point']['key_query'];
				$point = $row[$point_key];
				
				if(false === ($point = @DevblocksPlatform::parseGeoPointString($point)))
					continue;
				
				$row[$point_key] = sprintf('%f, %f', $point['latitude'], $point['longitude']);
				$rows[] = $row;
			}
		}
		
		return [
			'data' => $table,
			'_' => [
				'type' => 'worklist.geo.points',
				'format' => 'table',
			]
		];
	}
};