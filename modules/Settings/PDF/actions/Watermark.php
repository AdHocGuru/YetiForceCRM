<?php

/**
 * Returns special functions for PDF Settings.
 *
 * @copyright YetiForce Sp. z o.o
 * @license   YetiForce Public License 3.0 (licenses/LicenseEN.txt or yetiforce.com)
 * @author    Maciej Stencel <m.stencel@yetiforce.com>
 * @author    Mariusz Krzaczkowski <m.krzaczkowski@yetiforce.com>
 * @author    Rafal Pospiech <r.pospiech@yetiforce.com>
 */
class Settings_PDF_Watermark_Action extends Settings_Vtiger_Index_Action
{
	public function __construct()
	{
		$this->exposeMethod('delete');
		$this->exposeMethod('upload');
	}

	public function delete(\App\Request $request)
	{
		$recordId = $request->get('id');
		$pdfModel = Vtiger_PDF_Model::getInstanceById($recordId);
		$output = Settings_PDF_Record_Model::deleteWatermark($pdfModel);

		$response = new Vtiger_Response();
		$response->setResult($output);
		$response->emit();
	}

	public function upload(\App\Request $request)
	{
		$templateId = $request->get('template_id');
		$newName = basename($_FILES['watermark']['name'][0]);
		$newName = explode('.', $newName);
		if ($templateId) {
			$newName = $templateId . '.' . end($newName);
		} else {
			$newName = uniqid('', false) . '.' . end($newName);
		}
		$targetDir = Settings_PDF_Module_Model::$uploadPath;
		$targetFile = $targetDir . $newName;
		$uploadOk = 1;

		$fileInstance = \App\Fields\File::loadFromPath($_FILES['watermark']['tmp_name'][0]);
		if (!$fileInstance->validate('image')) {
			$uploadOk = 0;
		}

		// Check allowed upload file size
		if ($uploadOk && $_FILES['watermark']['size'][0] > \AppConfig::main('upload_maxsize')) {
			$uploadOk = 0;
		}
		$response = new Vtiger_Response();
		// Check if $uploadOk is set to 0 by an error
		if ($uploadOk === 1) {
			$db = App\Db::getInstance('admin');
			$watermarkImage = (new \App\Db\Query())->select(['watermark_image'])
				->from('a_#__pdf')
				->where(['pdfid' => $templateId])
				->scalar($db);
			if (file_exists($watermarkImage)) {
				unlink($watermarkImage);
			}
			// successful upload
			if ($fileInstance->moveFile($targetFile)) {
				$db->createCommand()
					->update('a_#__pdf', ['watermark_image' => $targetFile], ['pdfid' => $templateId])
					->execute();
				$response->setResult(['fileName' => $targetFile, 'base64' => \App\Fields\File::getImageBaseData($targetFile)]);
				return $response->emit();
			}
			$response->setError(500, App\Language::translate('LBL_WATERMARK_UPLOAD_ERROR', $request->getModule()));
			return $response->emit();
		}
		$response->setError(500, App\Language::translate('LBL_WATERMARK_UPLOAD_ERROR', $request->getModule()));
		$response->emit();
	}
}
