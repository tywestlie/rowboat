class QuestionsController < ApplicationController
  include AiAuthorization

  def new
    @query = Query.new
  end

  def create
    @query = Query.new(question: params.require(:query).permit(:question)[:question])

    if @query.save
      AnswerQuestionJob.perform_later(@query)
      redirect_to question_path(@query)
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    @query = Query.find(params[:id])
    @result = QueryExecutor.call(@query.generated_query) if @query.generated_query.present?
  end
end
