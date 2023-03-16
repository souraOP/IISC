import pandas as pd
import time
import logging
import re

from pathlib import Path
from iisc import INPUT_XLSX


# Define a custom formatter that adds color to log messages
class ColoredFormatter(logging.Formatter):
    def format(self, record):
        color = '\033[0m'  # reset color
        if record.levelno == logging.INFO:
            color = '\033[32m'  # green
        elif record.levelno == logging.WARNING:
            color = '\033[33m'  # yellow
        elif record.levelno == logging.ERROR:
            color = '\033[31m'  # red
        elif record.levelno == logging.CRITICAL:
            color = '\033[41m'  # red background
        message = color + logging.Formatter.format(self, record) + '\033[0m'
        return message


# Configure the logging system
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

handler = logging.StreamHandler()
handler.setFormatter(ColoredFormatter())

logger.addHandler(handler)


def validate_spreadsheet(path_xlsx: Path):
    """ check the inputs"""
    path_xlsx = Path(path_xlsx)
   
    logging.info(f"*** {path_xlsx} ***")
    start_time = time.time()
    
    # print(path_xlsx.suffix)
    
    if path_xlsx.suffix != ".xlsx":
        # print(path_xlsx.suffix)
        msg = f"excel file has wrong suffix: file_path = {path_xlsx}"
        logging.error(msg)
        return False

    try:
        xlsx_data = pd.read_excel(
            path_xlsx,
            sheet_name=None,
            # skiprows=[0],
            comment="#"
        )

    except Exception as err:
        logging.error(f"Problems reading xlsx file. Probably stored in incorrect format. "
                     f"Make sure files are in 'Excel 2007-365 (.xlsx).'")
        logging.info(str(err))
        return False

    # validate columns
    for sheet_name, df in xlsx_data.items():

        for c in df.columns:
            if not isinstance(c, str):
                msg = f"In sheet <{sheet_name}> the columns contain non-string values:{c} "
                logging.error(msg)

        success = True
        sheet_success = validate_excel_sheet(df, sheet_name, path_xlsx.stem)
    success = sheet_success and success

    if success:
        duration = time.time() - start_time
        logging.info(
            f"- {duration:.2f} [s] : Validated input file {path_xlsx.stem}")
        # print("Hello -Success print")
    return success


def validate_excel_sheet(df, sheet_name, file_id):
    """Validates the given excel sheet.

    :param df: loaded pandas.DataFrame
    :param sheet_name: name of spreadsheet
    :param study_id: study identifier
    :return: boolean validation status
    """

    validations = [
        validate_no_empty_rows(df, sheet_name, file_id),
        validate_format(df, sheet_name, file_id)]

    return all(validations)


def validate_no_empty_rows(df, sheet_name, file_id):
    """ validated that no emptye lines exist in sheet.

    :param df:
    :param sheet_name:
    :param study_id:
    :return:
    """
    if len(df.dropna(how='all').index) < len(df.index):
        msg = f"Sheet <{sheet_name}> of file <{file_id}.xlsx> contain " \
        f"empty lines. Remove the line or add a '#' as the first character in the line."
        logging.warning(msg)

    return True


def validate_format(df, sheet_name, study_id):
    """ validated excel format

    :param df:
    :param sheet_name:
    :param study_id:
    :return:
    """
    is_valid = True
    if not _validate_column_ids(df, sheet_name, study_id):
        is_valid = False

    for n, column in enumerate(df.columns):
        # if not _validate_lower_case(column, study_id, sheet_name, n):
        #     is_valid = False
        if not _validate_special_characters(column, study_id, sheet_name, n):
            is_valid = False
        if not _validate_no_whitespace(column, study_id, sheet_name, n):
            is_valid = False
    return is_valid


def _validate_lower_case(column, file_id, sheet_name, n):
    """Validate that  column name are lower case."""
    if column != column.lower():
        msg = f"Column names in all sheets must be lower case'. " \
              f"In sheet <{sheet_name}> of file <{file_id}.xlsx> {n}th " \
              f"column is <{column}>."
        logging.error(msg)
        return False
    return True


def _validate_special_characters(column_name, file_id, sheet_name,
                                 column_number):
    """ validate that no special characters are in column names.

    :param column_name:
    :param study_id:
    :param sheet_name:
    :param column_number:
    :return:
    """
    if not re.match("^[a-zA-Z0-9_]*$", column_name):
        msg = f"No special characters or whitespace allowed in column names. " \
              f"Allowed characters are 'a-zA-Z0-9_'." \
              f"In sheet <{sheet_name}> of file <{file_id}.xlsx> " \
              f"{column_number}th column is <{column_name}>."
        logging.error(msg)
        return False
    return True


def _validate_no_whitespace(column, file_id, sheet_name, n):
    """Validate that  column name has no white space."""
    if " " in column:
        msg = f"Column names in all sheets must not have any white space " \
              f"characters. In sheet <{sheet_name}> of file " \
              f"<{file_id}.xlsx> {n}th column is <{column}>."
        logging.error(msg)
        return False
    return True


def _validate_column_ids(df: pd.DataFrame, sheet_name, file_id):
    """Validate first column contains study id."""

    required_cols = {
        "t": "tail (edge)",
        "h": "head (edge)",
        "d": "diameter (edge)",
        "l": "length (edge)",
        "index": "index (node)",
        "nodes": "node ids (node)",
        "xpos": "x co-ordinate (node)",
        "ypos": "y co-ordinate (node)",
        "zpos": "z co-ordinate (node)",
        "hNode": "inlet node",
        "tNode": "inlet node"
    }

    is_valid = True
    for field in required_cols:
        if field not in df.columns:
            msg = f"Column in sheet <{sheet_name}> in <{file_id}.xlsx> must contain the tail information of edges"
            logging.error(msg)
            is_valid = False

    return is_valid


if __name__ == '__main__':
    # print(file_upload.file_name)
    # all_data = file_upload.objects.filter(uploader__id=request.user.id)
    validate_spreadsheet(path_xlsx=INPUT_XLSX)